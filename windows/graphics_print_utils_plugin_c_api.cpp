#include "include/graphics_print_utils/graphics_print_utils_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "graphics_print_utils_plugin.h"

void GraphicsPrintUtilsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  graphics_print_utils::GraphicsPrintUtilsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
