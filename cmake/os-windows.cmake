set_property(TARGET obs-browser PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
target_compile_definitions(
  obs-browser
  PRIVATE ENABLE_BROWSER_SHARED_TEXTURE $<$<CONFIG:Debug>:NDEBUG>
          $<$<CONFIG:Debug>:_HAS_ITERATOR_DEBUGGING=0>)
target_compile_options(obs-browser PRIVATE $<$<CONFIG:Debug>:/U_DEBUG>)

target_link_libraries(obs-browser PRIVATE CEF::Wrapper CEF::Library d3d11 dxgi)
target_link_options(obs-browser PRIVATE /IGNORE:4099)

configure_file(cmake/windows/obs-module.rc.in obs-browser.rc)
target_sources(obs-browser PRIVATE obs-browser.rc)

add_library(obs-browser-subprocess STATIC)
target_sources(
  obs-browser-subprocess
  PRIVATE # cmake-format: sortable
          browser-app.cpp browser-app.hpp browser-dummy-client.cpp browser-dummy-client.hpp cef-headers.hpp
          obs-browser-subprocess-win.cpp obs-browser-subprocess-win.hpp)
target_link_libraries(obs-browser-subprocess PUBLIC CEF::Wrapper CEF::Library nlohmann_json::nlohmann_json)
target_include_directories(obs-browser-subprocess PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/deps")
target_compile_features(obs-browser-subprocess PUBLIC cxx_std_20)
target_compile_definitions(obs-browser-subprocess PUBLIC ENABLE_BROWSER_SHARED_TEXTURE $<$<CONFIG:Debug>:NDEBUG>
                                                         $<$<CONFIG:Debug>:_HAS_ITERATOR_DEBUGGING=0>)
target_compile_options(obs-browser-subprocess PUBLIC $<$<CONFIG:Debug>:/U_DEBUG>)
set_property(TARGET obs-browser-subprocess PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")

add_executable(obs-browser-helper WIN32 EXCLUDE_FROM_ALL obs-browser-page.manifest obs-browser-page/obs-browser-page-main.cpp)
add_executable(OBS::browser-helper ALIAS obs-browser-helper)
target_link_libraries(obs-browser-helper PRIVATE obs-browser-subprocess)

configure_file(cmake/windows/obs-module-helper.rc.in obs-browser-page.rc)
target_sources(obs-browser-helper PRIVATE obs-browser-page.rc)

target_sources(obs-browser PRIVATE obs-browser-sandbox.h obs-browser-subprocess-win.cpp
                                   obs-browser-subprocess-win.hpp obs-browser-sandbox-selection.cpp
                                   obs-browser-sandbox-selection.hpp)

target_include_directories(obs-browser-helper PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/obs-browser-page")
set_property(TARGET obs-browser-helper PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
target_link_options(obs-browser-helper PRIVATE /IGNORE:4099 /SUBSYSTEM:WINDOWS)

if(TARGET CEF::Bootstrap)
  add_library(obs-browser-child MODULE obs-browser-child.cpp)
  set_property(TARGET obs-browser-child PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
  target_link_libraries(obs-browser-child PRIVATE obs-browser-subprocess)
  target_link_options(obs-browser-child PRIVATE /IGNORE:4099 "/PDBALTPATH:$<TARGET_PDB_FILE_NAME:obs-browser-child>")
  _target_install_obs(obs-browser-child DESTINATION "${OBS_PLUGIN_DESTINATION}/obs-browser")
  add_dependencies(obs-browser obs-browser-child)
endif()

target_link_libraries(obs-browser PRIVATE Ws2_32)
target_sources(obs-browser PRIVATE deps/ip-string-windows.cpp)

set(OBS_EXECUTABLE_DESTINATION "${OBS_PLUGIN_DESTINATION}")
set_target_properties_obs(
  obs-browser-helper
  PROPERTIES FOLDER plugins/obs-browser
             PREFIX ""
             OUTPUT_NAME obs-browser-page)

#make it dependence for obs-browser
add_dependencies(obs-browser obs-browser-helper)

if(BUILD_TESTING)
  include(CTest)

  add_executable(obs-browser-sandbox-selection-test)
  target_sources(
    obs-browser-sandbox-selection-test
    PRIVATE obs-browser-sandbox-selection.cpp obs-browser-sandbox-selection.hpp
            tests/obs-browser-sandbox-selection-test.cpp)
  target_include_directories(obs-browser-sandbox-selection-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  target_compile_features(obs-browser-sandbox-selection-test PRIVATE cxx_std_17)
  set_property(TARGET obs-browser-sandbox-selection-test PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
  target_compile_definitions(
    obs-browser-sandbox-selection-test
    PRIVATE $<$<CONFIG:Debug>:NDEBUG> $<$<CONFIG:Debug>:_HAS_ITERATOR_DEBUGGING=0>)
  target_compile_options(obs-browser-sandbox-selection-test PRIVATE $<$<CONFIG:Debug>:/U_DEBUG>)
  add_test(NAME obs-browser-sandbox-selection-test COMMAND obs-browser-sandbox-selection-test)
endif()
