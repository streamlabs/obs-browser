/******************************************************************************
 Copyright (C) 2026 by Streamlabs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 ******************************************************************************/

#include "obs-browser-subprocess-win.hpp"

#ifdef _WIN32

#include "browser-app.hpp"
#include "cef-headers.hpp"

#include <windows.h>

#include <charconv>
#include <string>
#include <system_error>
#include <thread>

namespace {

void shutdown_check_thread(DWORD parent_pid, DWORD main_thread_id, HANDLE shutdown_event)
{
	HANDLE parent = OpenProcess(SYNCHRONIZE, false, parent_pid);
	if (!parent)
		return;

	HANDLE handles[2] = {parent, shutdown_event};

	DWORD ret = WaitForMultipleObjects(2, handles, false, INFINITE);
	if (ret == WAIT_OBJECT_0) {
		PostThreadMessage(main_thread_id, WM_QUIT, 0, 0);
		ret = WaitForSingleObject(shutdown_event, 5000);
		if (ret != WAIT_OBJECT_0)
			TerminateProcess(GetCurrentProcess(), (UINT)-1);
	}

	CloseHandle(parent);
}

} // namespace

int ExecuteBrowserSubprocess(void *sandbox_info)
{
	PROCESS_POWER_THROTTLING_STATE power_throttling{};
	power_throttling.Version = PROCESS_POWER_THROTTLING_CURRENT_VERSION;
	power_throttling.ControlMask = PROCESS_POWER_THROTTLING_IGNORE_TIMER_RESOLUTION;
	SetProcessInformation(GetCurrentProcess(), ProcessPowerThrottling, &power_throttling, sizeof(power_throttling));

	std::thread shutdown_check;
	HANDLE shutdown_event = nullptr;
	CefMainArgs main_args(GetModuleHandleW(nullptr));
	CefRefPtr<CefCommandLine> command_line = CefCommandLine::CreateCommandLine();
	command_line->InitFromString(::GetCommandLineW());

	std::string parent_pid_str = command_line->GetSwitchValue("parent_pid");
	if (!parent_pid_str.empty()) {
		DWORD parent_pid = 0;
		const auto parse_result = std::from_chars(parent_pid_str.data(),
							  parent_pid_str.data() + parent_pid_str.size(), parent_pid);
		if (parse_result.ec == std::errc() &&
		    parse_result.ptr == parent_pid_str.data() + parent_pid_str.size() && parent_pid != 0) {
			shutdown_event = CreateEvent(nullptr, true, false, nullptr);
			if (shutdown_event) {
				shutdown_check = std::thread(shutdown_check_thread, parent_pid, GetCurrentThreadId(),
							     shutdown_event);
			}
		}
	}

	CefRefPtr<BrowserApp> main_app(new BrowserApp());
	int ret = CefExecuteProcess(main_args, main_app.get(), sandbox_info);

	/* Chromium browser subprocesses are generally terminated directly, but
	 * keep the parent watcher cleanup for normal process exits. */
	if (shutdown_check.joinable()) {
		SetEvent(shutdown_event);
		shutdown_check.join();
	}
	if (shutdown_event)
		CloseHandle(shutdown_event);

	return ret;
}

#endif
