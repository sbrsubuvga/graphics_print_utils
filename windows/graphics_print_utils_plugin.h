#ifndef FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_
#define FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace graphics_print_utils {

class GraphicsPrintUtilsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GraphicsPrintUtilsPlugin();

  virtual ~GraphicsPrintUtilsPlugin();

  // Disallow copy and assign.
  GraphicsPrintUtilsPlugin(const GraphicsPrintUtilsPlugin&) = delete;
  GraphicsPrintUtilsPlugin& operator=(const GraphicsPrintUtilsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace graphics_print_utils

#endif  // FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_
