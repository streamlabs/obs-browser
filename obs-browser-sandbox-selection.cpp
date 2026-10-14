/******************************************************************************
 Copyright (C) 2026 by Streamlabs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 ******************************************************************************/

#include "obs-browser-sandbox-selection.hpp"

#ifdef _WIN32

BrowserSandboxMode SelectBrowserSandboxMode(const BrowserSandboxExports &exports)
{
	if (!exports.abi_version)
		return BrowserSandboxMode::Legacy;

	if (exports.abi_version() != OBS_BROWSER_SANDBOX_ABI_VERSION)
		return BrowserSandboxMode::AbiVersionMismatch;

	if (!exports.create || !exports.destroy)
		return BrowserSandboxMode::MissingLifecycleExports;

	return BrowserSandboxMode::Enabled;
}

bool CreateBrowserSandboxInfo(const BrowserSandboxExports &exports, void **sandbox_info)
{
	if (!sandbox_info)
		return false;

	*sandbox_info = nullptr;
	if (!exports.create)
		return false;

	*sandbox_info = exports.create();
	return *sandbox_info != nullptr;
}

bool BrowserSandboxExecuteProcessSucceeded(int execute_result)
{
	return execute_result == -1;
}

#endif
