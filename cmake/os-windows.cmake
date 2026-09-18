set_property(TARGET obs-browser PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
target_compile_definitions(
  obs-browser
  PRIVATE ENABLE_BROWSER_SHARED_TEXTURE $<$<CONFIG:Debug>:NDEBUG>
          $<$<CONFIG:Debug>:_HAS_ITERATOR_DEBUGGING=0>)
target_compile_options(obs-browser PRIVATE $<$<CONFIG:Debug>:/U_DEBUG>)

target_link_libraries(obs-browser PRIVATE CEF::Wrapper CEF::Library d3d11 dxgi)
target_link_options(obs-browser PRIVATE /IGNORE:4099)

add_executable(obs-browser-helper WIN32 EXCLUDE_FROM_ALL)
add_executable(OBS::browser-helper ALIAS obs-browser-helper)

target_sources(
  obs-browser-helper
  PRIVATE # cmake-format: sortable
          browser-app.cpp browser-app.hpp cef-headers.hpp obs-browser-page.manifest obs-browser-sandbox.h
          obs-browser-subprocess-win.cpp obs-browser-subprocess-win.hpp
          obs-browser-page/obs-browser-page-main.cpp)

target_sources(obs-browser PRIVATE obs-browser-sandbox.h obs-browser-subprocess-win.cpp
                                   obs-browser-subprocess-win.hpp obs-browser-sandbox-selection.cpp
                                   obs-browser-sandbox-selection.hpp)

target_include_directories(obs-browser-helper PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/deps"
                                                      "${CMAKE_CURRENT_SOURCE_DIR}/obs-browser-page")

target_compile_features(obs-browser-helper PRIVATE cxx_std_17)
set_property(TARGET obs-browser-helper PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
target_compile_definitions(
  obs-browser-helper
  PRIVATE ENABLE_BROWSER_SHARED_TEXTURE $<$<CONFIG:Debug>:NDEBUG>
          $<$<CONFIG:Debug>:_HAS_ITERATOR_DEBUGGING=0>)
target_compile_options(obs-browser-helper PRIVATE $<$<CONFIG:Debug>:/U_DEBUG>)

target_link_libraries(obs-browser-helper PRIVATE CEF::Wrapper CEF::Library nlohmann_json::nlohmann_json)
target_link_options(obs-browser-helper PRIVATE /IGNORE:4099 /SUBSYSTEM:WINDOWS)

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
