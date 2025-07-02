//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

/**
 * @brief Registers all supported Flutter plugins with the provided plugin registry.
 *
 * This function enables the use of platform-specific plugins, such as permission handling and URL launching, by registering them with the given Flutter plugin registry.
 */
void RegisterPlugins(flutter::PluginRegistry* registry) {
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
