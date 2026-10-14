/******************************************************************************
 Copyright (C) 2026 by Streamlabs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 ******************************************************************************/

#pragma once

#ifdef _WIN32

#include "obs-browser-sandbox.h"

enum class BrowserSandboxMode {
	Legacy,
	Enabled,
	AbiVersionMismatch,
	MissingLifecycleExports,
};

struct BrowserSandboxExports {
	obs_browser_sandbox_abi_version_proc abi_version = nullptr;
	obs_browser_sandbox_info_create_proc create = nullptr;
	obs_browser_sandbox_info_destroy_proc destroy = nullptr;
};

BrowserSandboxMode SelectBrowserSandboxMode(const BrowserSandboxExports &exports);
bool CreateBrowserSandboxInfo(const BrowserSandboxExports &exports, void **sandbox_info);
bool BrowserSandboxExecuteProcessSucceeded(int execute_result);

#endif
