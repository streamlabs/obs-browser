/******************************************************************************
 Copyright (C) 2026 by Streamlabs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 ******************************************************************************/

#pragma once

/*
 * Windows sandbox ABI shared by the OBS executable and obs-browser. Keep this
 * C-only surface stable: the main executable owns CEF's sandbox library, and
 * the plugin discovers its lifecycle functions dynamically.
 */
#ifdef _WIN32

#include <stdint.h>

#define OBS_BROWSER_SANDBOX_ABI_VERSION 1u

#if defined(OBS_BROWSER_SANDBOX_HOST_IMPLEMENTATION)
#define OBS_BROWSER_SANDBOX_HOST_API __declspec(dllexport)
#else
#define OBS_BROWSER_SANDBOX_HOST_API
#endif

#if defined(OBS_BROWSER_SANDBOX_PLUGIN_IMPLEMENTATION)
#define OBS_BROWSER_SANDBOX_PLUGIN_API __declspec(dllexport)
#else
#define OBS_BROWSER_SANDBOX_PLUGIN_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

OBS_BROWSER_SANDBOX_HOST_API uint32_t __cdecl obs_browser_sandbox_abi_version(void);
OBS_BROWSER_SANDBOX_HOST_API void *__cdecl obs_browser_sandbox_info_create(void);
OBS_BROWSER_SANDBOX_HOST_API void __cdecl obs_browser_sandbox_info_destroy(void *sandbox_info);

OBS_BROWSER_SANDBOX_PLUGIN_API int __cdecl obs_browser_execute_subprocess(void *sandbox_info);

#ifdef __cplusplus
}
#endif

typedef uint32_t(__cdecl *obs_browser_sandbox_abi_version_proc)(void);
typedef void *(__cdecl *obs_browser_sandbox_info_create_proc)(void);
typedef void(__cdecl *obs_browser_sandbox_info_destroy_proc)(void *sandbox_info);
typedef int(__cdecl *obs_browser_execute_subprocess_proc)(void *sandbox_info);

#undef OBS_BROWSER_SANDBOX_HOST_API
#undef OBS_BROWSER_SANDBOX_PLUGIN_API

#endif
