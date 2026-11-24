#define OBS_BROWSER_SANDBOX_PLUGIN_IMPLEMENTATION
#include "obs-browser-sandbox.h"
#include "obs-browser-subprocess-win.hpp"

extern "C" int __cdecl obs_browser_execute_subprocess(void *sandbox_info)
{
	return sandbox_info ? ExecuteBrowserSubprocess(sandbox_info) : -1;
}
