/******************************************************************************
 Copyright (C) 2026 by Streamlabs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 ******************************************************************************/

#include "obs-browser-sandbox-selection.hpp"

#include <cstdio>

namespace {

uint32_t __cdecl expected_abi_version()
{
	return OBS_BROWSER_SANDBOX_ABI_VERSION;
}

uint32_t __cdecl incompatible_abi_version()
{
	return OBS_BROWSER_SANDBOX_ABI_VERSION + 1;
}

void *__cdecl create_sandbox_info()
{
	return reinterpret_cast<void *>(1);
}

void *__cdecl create_null_sandbox_info()
{
	return nullptr;
}

void __cdecl destroy_sandbox_info(void *) {}

bool expect(bool condition, const char *message)
{
	if (condition)
		return true;

	std::fprintf(stderr, "FAILED: %s\n", message);
	return false;
}

} // namespace

int main()
{
	bool passed = true;
	BrowserSandboxExports exports;

	passed &= expect(SelectBrowserSandboxMode(exports) == BrowserSandboxMode::Legacy,
			 "missing ABI export uses the legacy helper path");

	exports.abi_version = incompatible_abi_version;
	passed &= expect(SelectBrowserSandboxMode(exports) == BrowserSandboxMode::AbiVersionMismatch,
			 "an advertised incompatible ABI fails closed");

	exports.abi_version = expected_abi_version;
	exports.destroy = destroy_sandbox_info;
	passed &= expect(SelectBrowserSandboxMode(exports) == BrowserSandboxMode::MissingLifecycleExports,
			 "an advertised ABI without a create lifecycle export fails closed");

	exports.create = create_null_sandbox_info;
	void *sandbox_info = reinterpret_cast<void *>(1);
	passed &= expect(SelectBrowserSandboxMode(exports) == BrowserSandboxMode::Enabled,
			 "complete matching exports select the sandbox path");
	passed &= expect(!CreateBrowserSandboxInfo(exports, &sandbox_info) && !sandbox_info,
			 "a null sandbox-info creation fails closed");

	exports.create = create_sandbox_info;
	passed &= expect(CreateBrowserSandboxInfo(exports, &sandbox_info) && sandbox_info,
			 "a non-null sandbox-info creation succeeds");
	passed &= expect(BrowserSandboxExecuteProcessSucceeded(-1),
			 "the browser-process CefExecuteProcess result is -1");
	passed &= expect(!BrowserSandboxExecuteProcessSucceeded(0),
			 "a non--1 CefExecuteProcess result fails closed");

	return passed ? 0 : 1;
}
