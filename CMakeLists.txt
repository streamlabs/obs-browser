cmake_minimum_required(VERSION 3.28...3.30)

option(ENABLE_BROWSER "Enable browser source plugin (required Chromium Embedded Framework)" OFF)

if(NOT ENABLE_BROWSER)
  target_disable(obs-browser)
  target_disable_feature(obs-browser "Browser sources are not enabled by default (set CEF_ROOT_DIR and ENABLE_BROWSER)")

  return()
endif()

find_package(CEF 95 REQUIRED)
find_package(nlohmann_json 3.11 REQUIRED)

include(CMakePushCheckState)
include(CheckCXXSourceCompiles)
cmake_push_check_state(RESET)
set(CMAKE_REQUIRED_INCLUDES "${CEF_ROOT_DIR}")
check_cxx_source_compiles(
  "#include <include/internal/cef_types.h>
   int main() { return CEF_PERMISSION_TYPE_LOOPBACK_NETWORK; }"
  CEF_HAS_LOOPBACK_NETWORK_PERMISSION)
check_cxx_source_compiles(
  "#include <include/internal/cef_types.h>
   int main() { cef_settings_t settings{}; settings.chrome_runtime = 1; return 0; }"
  CEF_HAS_CHROME_RUNTIME_SETTING)
cmake_pop_check_state()

add_library(obs-browser MODULE)
add_library(OBS::browser ALIAS obs-browser)
target_compile_definitions(
  obs-browser
  PRIVATE $<$<BOOL:${CEF_HAS_LOOPBACK_NETWORK_PERMISSION}>:CEF_HAS_LOOPBACK_NETWORK_PERMISSION>
          $<$<BOOL:${CEF_HAS_CHROME_RUNTIME_SETTING}>:CEF_HAS_CHROME_RUNTIME_SETTING>)

option(ENABLE_BROWSER_PANELS "Enable Qt web browser panel support" OFF)
mark_as_advanced(ENABLE_BROWSER_PANELS)

target_sources(
  obs-browser
  PRIVATE # cmake-format: sortable
    browser-app.cpp
    browser-app.hpp
    browser-client.cpp
    browser-client.hpp
    browser-dummy-client.cpp
    browser-dummy-client.hpp
    browser-scheme.cpp
    browser-scheme.hpp
    browser-version.h
    cef-headers.hpp
    deps/base64/base64.cpp
    deps/base64/base64.hpp
    deps/ip-string.hpp
    deps/signal-restore.cpp
    deps/signal-restore.hpp
    deps/wide-string.cpp
    deps/wide-string.hpp
    obs-browser-plugin.cpp
    obs-browser-source.cpp
    obs-browser-source.hpp
)

if(OS_MACOS)
  list(APPEND obs-browser_SOURCES
    browser-mac.mm
    browser-mac.h)
endif()

target_sources(obs-browser PRIVATE ${obs-browser_SOURCES})
target_include_directories(obs-browser PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/deps")

target_compile_features(obs-browser PRIVATE cxx_std_20)
# Note: OBS::websocket-api was removed from this list
target_link_libraries(obs-browser PRIVATE OBS::libobs OBS::frontend-api nlohmann_json::nlohmann_json)

if(OS_WINDOWS)
  include(cmake/os-windows.cmake)
elseif(OS_MACOS)
  include(cmake/os-macos.cmake)
elseif(OS_LINUX)
  include(cmake/os-linux.cmake)
endif()

if(ENABLE_BROWSER_PANELS)
  include(cmake/feature-panels.cmake)
endif()

set_target_properties_obs(obs-browser PROPERTIES FOLDER plugins/obs-browser PREFIX "")
