#ifndef FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_
#define FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _GraphicsPrintUtilsPlugin GraphicsPrintUtilsPlugin;
typedef struct {
  GObjectClass parent_class;
} GraphicsPrintUtilsPluginClass;

FLUTTER_PLUGIN_EXPORT GType graphics_print_utils_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void graphics_print_utils_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_GRAPHICS_PRINT_UTILS_PLUGIN_H_
