# We currently do not use Qt in obs-studio-node so its' best to leave this off. OBS.app is a QtApplication so this makes sense for them.
#find_package(Qt6 REQUIRED Widgets)

# Do not turn on ENABLE_BROWSER_QT_LOOP. Once again, obs-studio-node is not a Qt app. We could make it one kinda easily as long as the exact same
# binaries we use to build obs-browser is packed up and shipped along like libobs.framework. But for now we dont need the ENABLE_BROWSER_QT_LOOP flag
target_compile_definitions(obs-browser PRIVATE ENABLE_BROWSER_SHARED_TEXTURE)

if(CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL 14.0.3)
  target_compile_options(obs-browser PRIVATE -Wno-error=unqualified-std-cast-call)
endif()

# Streamlabs removed Qt::Widgets. Our obs-browser does not use Qt framework
target_link_libraries(obs-browser PRIVATE CEF::Wrapper "$<LINK_LIBRARY:FRAMEWORK,CoreFoundation.framework>"
                                          "$<LINK_LIBRARY:FRAMEWORK,AppKit.framework>")

set(helper_basename browser-helper)
set(helper_output_name "obs64 Helper") # See cef_types.h documentation for browser_subprocess_path setting
set(helper_suffixes "::" " (GPU):_gpu:.gpu" " (Plugin):_plugin:.plugin" " (Renderer):_renderer:.renderer")

foreach(helper IN LISTS helper_suffixes)
  string(REPLACE ":" ";" helper ${helper})
  list(GET helper 0 helper_name)
  list(GET helper 1 helper_target)
  list(GET helper 2 helper_plist)

  set(target_name ${helper_basename}${helper_target})
  set(target_output_name "${helper_output_name}${helper_name}")
  set(EXECUTABLE_NAME "${target_output_name}")
  set(BUNDLE_ID_SUFFIX ${helper_plist})

  configure_file(cmake/macos/Info-helper.plist.in Info-Helper${helper_plist}.plist)

  add_executable(${target_name} MACOSX_BUNDLE EXCLUDE_FROM_ALL)
  add_executable(OBS::${target_name} ALIAS ${target_name})

  target_sources(
    ${target_name} PRIVATE # cmake-format: sortable
                           browser-app.cpp browser-app.hpp cef-headers.hpp obs-browser-page/obs-browser-page-main.cpp)

  target_compile_definitions(${target_name} PRIVATE ENABLE_BROWSER_SHARED_TEXTURE)

  if(CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL 14.0.3)
    target_compile_options(${target_name} PRIVATE -Wno-error=unqualified-std-cast-call)
  endif()

  target_include_directories(${target_name} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/deps"
                                                    "${CMAKE_CURRENT_SOURCE_DIR}/obs-browser-page")

  target_link_libraries(${target_name} PRIVATE CEF::Wrapper nlohmann_json::nlohmann_json)

  set_target_properties(
    ${target_name}
    PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info-Helper${helper_plist}.plist"
               OUTPUT_NAME "${target_output_name}"
               FOLDER plugins/obs-browser/Helpers
               XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER com.obsproject.obs-studio.helper${helper_plist}
               XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS
               "${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos/entitlements-helper${helper_plist}.plist")
endforeach()

set_target_properties(
  obs-browser
  PROPERTIES AUTOMOC ON
             AUTOUIC ON
             AUTORCC ON)
