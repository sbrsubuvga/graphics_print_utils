import 'dart:isolate';
import 'dart:typed_data';

import 'package:barcode_image/barcode_image.dart';
import 'package:graphics_print_utils/fonts/lithos_18.dart';
import 'package:graphics_print_utils/fonts/lithos_18_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_22.dart';
import 'package:graphics_print_utils/fonts/lithos_22_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_24.dart';
import 'package:graphics_print_utils/fonts/lithos_24_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_26_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_34_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_40_bold.dart';
import 'package:graphics_print_utils/resources/graphics_print_utils_manager.dart';
import 'package:image/image.dart' as img;
import 'package:image/image.dart' show BitmapFont;

// Command types for queuing operations
abstract class _DrawCommand {
  void execute(GraphicsPrintUtils util);
}

class _TextCommand extends _DrawCommand {
  final String text;
  final PrintTextStyle? style;
  _TextCommand(this.text, this.style);
  @override
  void execute(GraphicsPrintUtils util) => util.text(text, style: style);
}

class _LineCommand extends _DrawCommand {
  final int thickness;
  _LineCommand(this.thickness);
  @override
  void execute(GraphicsPrintUtils util) => util.line(thickness: thickness);
}

class _DottedLineCommand extends _DrawCommand {
  final int thickness;
  final int dotWidth;
  final int spacing;
  _DottedLineCommand(this.thickness, this.dotWidth, this.spacing);
  @override
  void execute(GraphicsPrintUtils util) => util.dottedLine(
        thickness: thickness,
        dotWidth: dotWidth,
        spacing: spacing,
      );
}

class _ImageCommand extends _DrawCommand {
  final Uint8List imageBytes; // Serialized image as PNG bytes
  final int? width;
  final int? height;
  final PrintAlign align;
  _ImageCommand(this.imageBytes, this.width, this.height, this.align);
  @override
  void execute(GraphicsPrintUtils util) {
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage != null) {
      util.image(
        decodedImage,
        width: width,
        height: height,
        align: align,
      );
    }
  }
}

class _QrCommand extends _DrawCommand {
  final String data;
  final int qrSize;
  final PrintAlign align;
  _QrCommand(this.data, this.qrSize, this.align);
  @override
  void execute(GraphicsPrintUtils util) => util.qr(
        data,
        qrSize: qrSize,
        align: align,
      );
}

class _BarcodeCommand extends _DrawCommand {
  final String data;
  final String barcodeType; // Serialized barcode type name
  final int width;
  final int height;
  final PrintAlign align;
  _BarcodeCommand(this.data, this.barcodeType, this.width, this.height, this.align);
  @override
  void execute(GraphicsPrintUtils util) {
    // Reconstruct barcode from type string
    Barcode barcode;
    switch (barcodeType) {
      case 'code128':
        barcode = Barcode.code128();
        break;
      case 'code39':
        barcode = Barcode.code39();
        break;
      case 'ean13':
        barcode = Barcode.ean13();
        break;
      case 'ean8':
        barcode = Barcode.ean8();
        break;
      case 'itf':
        barcode = Barcode.itf();
        break;
      case 'upcA':
        barcode = Barcode.upcA();
        break;
      case 'upcE':
        barcode = Barcode.upcE();
        break;
      default:
        barcode = Barcode.code128();
    }
    util.barcode(
      data,
      barcode: barcode,
      width: width,
      height: height,
      align: align,
    );
  }
}

class _RowCommand extends _DrawCommand {
  final List<PrintColumn> columns;
  final int spacing;
  _RowCommand(this.columns, this.spacing);
  @override
  void execute(GraphicsPrintUtils util) => util.row(
        columns: columns,
        spacing: spacing,
      );
}

class _FeedCommand extends _DrawCommand {
  final int lines;
  _FeedCommand(this.lines);
  @override
  void execute(GraphicsPrintUtils util) => util.feed(lines: lines);
}

/// Command-based version of GraphicsPrintUtils that queues operations
/// and executes them in an isolate when draw() is called.
/// 
/// This allows you to prepare all drawing operations synchronously,
/// then execute them in a background isolate to keep the UI responsive.
/// 
/// Usage:
/// ```dart
/// final builder = GraphicsPrintUtilsCommandBased(
///   paperSize: PrintPaperSize.mm80,
///   margin: PrintMargin(left: 10, right: 10),
/// );
/// 
/// // Prepare all operations (runs synchronously, no isolate yet)
/// builder.feed(lines: 1);
/// builder.text("SuperMart", style: PrintTextStyle(
///   fontSize: PrintFontSize.large,
///   align: PrintAlign.center,
///   bold: true,
/// ));
/// builder.line();
/// builder.qr("https://example.com");
/// builder.barcode('1259854', barcode: Barcode.code128());
/// 
/// // Execute all operations in isolate and get result
/// final pngBytes = await builder.draw();
/// ```
class GraphicsPrintUtilsCommandBased {
  final PrintPaperSize paperSize;
  final PrintMargin margin;
  final PrintTextStyle? style;
  final List<_DrawCommand> _commandQueue = [];

  GraphicsPrintUtilsCommandBased({
    this.paperSize = PrintPaperSize.mm80,
    this.margin = const PrintMargin(),
    PrintTextStyle? style,
  }) : style = style;

  /// Add text to the drawing queue
  void text(String text, {PrintTextStyle? style}) {
    _commandQueue.add(_TextCommand(text, style));
  }

  /// Add a horizontal line to the drawing queue
  void line({int thickness = 1}) {
    _commandQueue.add(_LineCommand(thickness));
  }

  /// Add a dotted horizontal line to the drawing queue
  void dottedLine({
    int thickness = 1,
    int dotWidth = 5,
    int spacing = 3,
  }) {
    _commandQueue.add(_DottedLineCommand(thickness, dotWidth, spacing));
  }

  /// Add an image to the drawing queue
  /// The image is serialized to PNG bytes for transfer to the isolate
  void image(
    img.Image subImage, {
    int? width,
    int? height,
    PrintAlign align = PrintAlign.left,
  }) {
    // Serialize image to PNG bytes for isolate transfer
    final imageBytes = img.encodePng(subImage);
    _commandQueue.add(_ImageCommand(imageBytes, width, height, align));
  }

  /// Add a QR code to the drawing queue
  void qr(
    String data, {
    int qrSize = 150,
    PrintAlign align = PrintAlign.center,
  }) {
    _commandQueue.add(_QrCommand(data, qrSize, align));
  }

  /// Add a barcode to the drawing queue
  /// The barcode type is serialized as a string for transfer to the isolate
  void barcode(
    String data, {
    required Barcode barcode,
    int width = 300,
    int height = 120,
    PrintAlign align = PrintAlign.center,
  }) {
    // Serialize barcode type to string by checking runtime type
    String barcodeType;
    final typeName = barcode.runtimeType.toString().toLowerCase();
    if (typeName.contains('code128')) {
      barcodeType = 'code128';
    } else if (typeName.contains('code39')) {
      barcodeType = 'code39';
    } else if (typeName.contains('ean13')) {
      barcodeType = 'ean13';
    } else if (typeName.contains('ean8')) {
      barcodeType = 'ean8';
    } else if (typeName.contains('itf')) {
      barcodeType = 'itf';
    } else if (typeName.contains('upca')) {
      barcodeType = 'upcA';
    } else if (typeName.contains('upce')) {
      barcodeType = 'upcE';
    } else {
      barcodeType = 'code128'; // default
    }
    _commandQueue.add(_BarcodeCommand(data, barcodeType, width, height, align));
  }

  /// Add a row to the drawing queue
  void row({
    required List<PrintColumn> columns,
    int spacing = 10,
  }) {
    _commandQueue.add(_RowCommand(columns, spacing));
  }

  /// Add feed (blank lines) to the drawing queue
  void feed({int lines = 1}) {
    _commandQueue.add(_FeedCommand(lines));
  }

  /// Calculate the total height needed for all queued commands
  /// This simulates all commands without actually drawing to determine the final height
  int _calculateTotalHeight() {
    int runningHeight = 0;
    final defaultFont = lithos22;
    
    // Font lookup maps (same as in GraphicsPrintUtils)
    final fontMap58 = {
      'small_false': () => lithos18,
      'small_true': () => lithos18Bold,
      'medium_false': () => lithos22,
      'medium_true': () => lithos22Bold,
      'large_false': () => lithos22Bold,
      'large_true': () => lithos26Bold,
    };
    
    final fontMap80 = {
      'small_false': () => lithos22,
      'small_true': () => lithos22Bold,
      'medium_false': () => lithos24,
      'medium_true': () => lithos24Bold,
      'large_false': () => lithos34Bold,
      'large_true': () => lithos40Bold,
    };
    
    BitmapFont _getFont(PrintTextStyle? style) {
      if (style == null) return defaultFont;
      final map = paperSize == PrintPaperSize.mm58 ? fontMap58 : fontMap80;
      final key = '${style.fontSize.name}_${style.bold}';
      return map[key]?.call() ?? defaultFont;
    }
    
    // Helper function to calculate text height recursively (matching GraphicsPrintUtils behavior)
    int _calculateTextHeight(String text, PrintTextStyle? textStyle) {
      if (text.isEmpty) return 0;
      
      final textFont = _getFont(textStyle ?? style);
      final maxWidth = paperSize.width - margin.width;
      final words = text.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) return 0;
      
      // Simulate the text wrapping logic from GraphicsPrintUtils
      int lineCount = 0;
      int wordIndex = 0;
      
      while (wordIndex < words.length) {
        StringBuffer buffer = StringBuffer();
        int wordsInLine = 0;
        
        // Build a line
        while (wordIndex < words.length) {
          final testWord = words[wordIndex];
          final testLine = buffer.isEmpty ? testWord : '${buffer.toString()} $testWord';
          final lineWidth = textFont.getMetrics(testLine).width;
          
          if (lineWidth <= maxWidth) {
            if (buffer.isNotEmpty) buffer.write(' ');
            buffer.write(testWord);
            wordsInLine++;
            wordIndex++;
          } else {
            break;
          }
        }
        
        if (wordsInLine == 0 && wordIndex < words.length) {
          // Word too long, force it
          wordsInLine = 1;
          wordIndex++;
        }
        
        if (wordsInLine > 0) {
          lineCount++;
        }
      }
      
      final lineHeight = textFont.lineHeight.toInt();
      final totalHeight = lineHeight + (lineHeight ~/ 12);
      return totalHeight * lineCount;
    }
    
    // Process each command to calculate height
    for (final command in _commandQueue) {
      if (command is _TextCommand) {
        runningHeight += _calculateTextHeight(command.text, command.style);
        
      } else if (command is _LineCommand) {
        runningHeight += 5 + command.thickness + 10;
        
      } else if (command is _DottedLineCommand) {
        runningHeight += 5 + command.thickness + 10;
        
      } else if (command is _ImageCommand) {
        // Decode image to get actual dimensions
        final decodedImage = img.decodeImage(command.imageBytes);
        if (decodedImage != null) {
          final imageHeight = command.height ?? decodedImage.height;
          runningHeight += imageHeight + 5;
        }
        
      } else if (command is _QrCommand) {
        // QR code height is the qrSize
        runningHeight += command.qrSize + 5;
        
      } else if (command is _BarcodeCommand) {
        // Barcode height is specified in command
        runningHeight += command.height + 5;
        
      } else if (command is _RowCommand) {
        if (command.columns.isEmpty) continue;
        
        final totalWidth = paperSize.width - margin.width - (command.spacing * (command.columns.length - 1));
        final totalRatio = command.columns.fold(0, (sum, col) => sum + col.flex);
        
        int maxLines = 0;
        
        // Calculate lines for each column
        for (final column in command.columns) {
          if (column.text.isEmpty) {
            maxLines = maxLines > 0 ? maxLines : 1;
            continue;
          }
          
          final columnFont = _getFont(column.style);
          final columnWidth = (totalWidth * (column.flex / totalRatio)).round();
          final words = column.text.split(' ').where((w) => w.isNotEmpty).toList();
          
          if (words.isEmpty) {
            maxLines = maxLines > 0 ? maxLines : 1;
            continue;
          }
          
          int lineCount = 0;
          String currentLine = '';
          
          for (final word in words) {
            final testLine = currentLine.isEmpty ? word : '$currentLine $word';
            final lineWidth = columnFont.getMetrics(testLine).width;
            
            if (lineWidth <= columnWidth) {
              currentLine = testLine;
            } else {
              if (currentLine.isNotEmpty) {
                lineCount++;
              }
              currentLine = word;
            }
          }
          if (currentLine.isNotEmpty) {
            lineCount++;
          }
          
          if (lineCount == 0) lineCount = 1;
          if (maxLines < lineCount) {
            maxLines = lineCount;
          }
        }
        
        final columnFont = _getFont(command.columns.first.style);
        final lineHeight = columnFont.lineHeight.toInt();
        runningHeight += (maxLines * lineHeight) + (lineHeight ~/ 12);
        
      } else if (command is _FeedCommand) {
        final feedFont = _getFont(style);
        final lineHeight = feedFont.lineHeight.toInt();
        runningHeight += (lineHeight + 10) * command.lines;
      }
    }
    
    return runningHeight;
  }

  /// Execute all queued operations in an isolate and return the PNG bytes.
  /// 
  /// This runs all drawing operations in a background isolate to keep UI responsive.
  /// All commands are executed sequentially on a new GraphicsPrintUtils instance
  /// created inside the isolate.
  /// 
  /// Returns the final PNG image bytes.
  Future<Uint8List> build() async {
    // Pre-calculate the total height needed
    final calculatedHeight = _calculateTotalHeight();
    // Add some padding to avoid resizing (20% buffer)
    final initialHeight = (calculatedHeight * 1.2).round();
    
    // Capture all data needed for the isolate (must be serializable)
    final commands = List<_DrawCommand>.from(_commandQueue);
    final paperSizeCopy = paperSize;
    final marginCopy = margin;
    final styleCopy = style;

    return await Isolate.run(() {
      // Create a new GraphicsPrintUtils instance inside the isolate with pre-calculated height
      final util = GraphicsPrintUtils(
        paperSize: paperSizeCopy,
        margin: marginCopy,
        style: styleCopy,
        initialHeight: initialHeight,
      );

      // Execute all queued commands sequentially
      for (final command in commands) {
        command.execute(util);
      }

      // Return the final PNG bytes
      return util.build();
    });
  }

  /// Clear all queued commands
  void clear() {
    _commandQueue.clear();
  }

  /// Get the number of queued commands
  int get commandCount => _commandQueue.length;
}

