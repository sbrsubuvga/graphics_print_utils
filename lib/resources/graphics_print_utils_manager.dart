import 'dart:typed_data';

import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/services.dart';
import 'package:graphics_print_utils/fonts/lithos_18.dart';
import 'package:graphics_print_utils/fonts/lithos_18_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_22_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_24.dart';
import 'package:graphics_print_utils/fonts/lithos_24_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_26_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_34_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_40_bold.dart';
import 'package:graphics_print_utils/fonts/shape_arabic.dart';
import 'package:image/image.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import '../fonts/lithos_22.dart';

class GraphicsPrintUtils {
  late img.Image utilImage;
  int runningHeight = 0;
  PrintMargin margin = PrintMargin(left: 5, right: 5);
  final PrintPaperSize paperSize;
  BitmapFont font = lithos22;
  final textColor = ColorUint1.rgba(0, 0, 0, 255);
  
  // Dynamic height management constants
  static const int _initialHeight = 5000; // Start with smaller initial height
  static const double _growthFactor = 1.5; // Grow by 50% each time (exponential growth)
  static const int _minGrowth = 200; // Minimum growth amount


// Optimized font lookup with map
static final Map<String, BitmapFont Function()> _fontMap58 = {
  'small_false': () => lithos18,
  'small_true': () => lithos18Bold,
  'medium_false': () => lithos22,
  'medium_true': () => lithos22Bold,
  'large_false': () => lithos22Bold,
  'large_true': () => lithos26Bold,
};

static final Map<String, BitmapFont Function()> _fontMap80 = {
  'small_false': () => lithos22,
  'small_true': () => lithos22Bold,
  'medium_false': () => lithos24,
  'medium_true': () => lithos24Bold,
  'large_false': () => lithos34Bold,
  'large_true': () => lithos40Bold,
};

  // GraphicsPrintUtils({
  //   this.paperSize = PrintPaperSize.mm80,
  //   this.margin = const PrintMargin(),
  //   PrintTextStyle? style = const PrintTextStyle(),
  // }) {
  //   // Start with a smaller initial height, will grow dynamically as needed
  //   utilImage = img.Image(width: paperSize.width, height: _initialHeight);
  //   fill(utilImage, color: ColorUint1.rgba(255, 255, 255, 255));
  //   if (style != null) {
  //     font = _getFont(style, paperSize);
  //   }
  // }

  GraphicsPrintUtils({
  this.paperSize = PrintPaperSize.mm80,
  this.margin = const PrintMargin(),
  PrintTextStyle? style = const PrintTextStyle(),
  int? initialHeight,
}) {
  // Use provided initial height or default
  final height = initialHeight ?? _initialHeight;
  
  // Create image with white background in one step
  utilImage = img.Image(
    width: paperSize.width, 
    height: height,
    numChannels: 4, // RGBA
  );
  
  // Optimized: fill only once during initialization
  img.fillRect(
    utilImage,
    x1: 0,
    y1: 0,
    x2: paperSize.width,
    y2: height,
    color: img.ColorRgba8(255, 255, 255, 255),
  );
  
  if (style != null) {
    font = _getFont(style, paperSize);
  }
}

BitmapFont _getFont(PrintTextStyle style, PrintPaperSize paperSize) { 
  final map = paperSize == PrintPaperSize.mm58 ? _fontMap58 : _fontMap80;
  final key = '${style.fontSize.name}_${style.bold}';
  return map[key]?.call() ?? lithos22;
}

  // BitmapFont _getFont(PrintTextStyle style,PrintPaperSize paperSize){
  //   if(paperSize == PrintPaperSize.mm58){
  //     return _getFont2(style);
  //   }
  //   else{
  //     return _getFont3(style);
  //   }
  // }

  // BitmapFont _getFont3(PrintTextStyle style) {
  //   BitmapFont myFont = lithos22;
  //   switch (style.fontSize) {
  //     case PrintFontSize.small:
  //       myFont = lithos22;
  //       if(style.bold){
  //         myFont=lithos22Bold;
  //       }
  //       break;
  //     case PrintFontSize.medium:
  //       myFont = lithos24;
  //       if(style.bold){
  //         myFont=lithos24Bold;
  //       }
  //       break;
  //     case PrintFontSize.large:
  //       myFont = lithos34Bold;
  //       if(style.bold){
  //         myFont=lithos40Bold;
  //       }
  //       break;
  //   }
  //   return myFont;
  // }
  
  // BitmapFont _getFont2(PrintTextStyle style) {
  //   BitmapFont myFont = lithos22;
  //   switch (style.fontSize) {
  //     case PrintFontSize.small:
  //       myFont = lithos18;
  //       if(style.bold){
  //         myFont=lithos18Bold;
  //       }
  //       break;
  //     case PrintFontSize.medium:
  //       myFont = lithos22;
  //       if(style.bold){
  //         myFont=lithos22Bold;
  //       }
  //       break;
  //     case PrintFontSize.large:
  //       myFont = lithos22Bold;
  //       if(style.bold){
  //         myFont=lithos26Bold;
  //       }
  //       break;
  //   }
  //   return myFont;
  // }


  void _ensureHeight(int requiredHeight) 
  {
    if (requiredHeight <= utilImage.height) {
      return;
    }
    print("******************* ensureHeight ${requiredHeight} ${utilImage.height}");
    
    // Exponential growth strategy: grow by growthFactor, but ensure minimum growth
    // This reduces the number of resize operations while avoiding excessive memory usage
    final currentHeight = utilImage.height;
    final growthAmount = (_initialHeight * _growthFactor).round() - _initialHeight;
    final minGrowth = _minGrowth;
    final actualGrowth = growthAmount > minGrowth ? growthAmount : minGrowth;
    
    // Calculate new height: ensure it's at least requiredHeight, but grow more to reduce future resizes
    final newHeight = (requiredHeight > currentHeight + actualGrowth) 
        ? requiredHeight + actualGrowth  // If required is much larger, grow more
        : (currentHeight * _growthFactor).round(); // Otherwise use exponential growth
    
    final resizedImage = img.Image(
      width: utilImage.width, 
      height: newHeight,
    );
    fill(resizedImage, color: ColorUint1.rgba(255, 255, 255, 255));
    
    // Copy existing content to new image
    img.compositeImage(
      resizedImage,
      utilImage,
      blend: img.BlendMode.direct,
    );
    utilImage = resizedImage;
  }

  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }


  void text(String text, {PrintTextStyle? style}) {
    if (text.isEmpty) return; // Early exit
     
     
    bool rtl = isArabic(text); // Determine direction
    img.BitmapFont textFont = font;
    PrintAlign align = PrintAlign.left;

    if (rtl) {
      textFont = lithos22;
      text = ShapeArabic.shape(text); // Shape once
    }

    if (style != null) {
      textFont = _getFont(style, paperSize);
      align = style.align;
    }

    int maxWidth = paperSize.width - margin.width;

    // Line breaking (reverse for RTL)
     // Split words once
  final words = text.split(' ');
  if (words.isEmpty) return;
  // Remove empty strings efficiently
  final nonEmptyWords = words.where((e) => e.isNotEmpty).toList(growable: false);
  if (nonEmptyWords.isEmpty) return;
  
  // Build line more efficiently
  final buffer = StringBuffer();
  int wordCount = 0;
  int lastValidWidth = 0;
  int lastValidCount = 0;

 if (rtl) {
    // RTL: iterate backwards
    for (int i = nonEmptyWords.length - 1; i >= 0; i--) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(nonEmptyWords[i]);
      
      final lineWidth = textFont.getMetrics(buffer.toString()).width;
      
      if (lineWidth <= maxWidth) {
        lastValidWidth = lineWidth;
        lastValidCount = ++wordCount;
      } else {
        break;
      }
    }
  } else {
    // LTR: iterate forward
    for (int i = 0; i < nonEmptyWords.length; i++) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(nonEmptyWords[i]);
      
      final lineWidth = textFont.getMetrics(buffer.toString()).width;
      
      if (lineWidth <= maxWidth) {
        lastValidWidth = lineWidth;
        lastValidCount = ++wordCount;
      } else {
        break;
      }
    }
  }
if (lastValidCount == 0) {
    // Word too long, force it
    lastValidCount = 1;
    lastValidWidth = textFont.getMetrics(nonEmptyWords[0]).width;
  }
  
  // Build final line string
  final currentLine = rtl 
      ? nonEmptyWords.sublist(nonEmptyWords.length - lastValidCount).reversed.join(' ')
      : nonEmptyWords.sublist(0, lastValidCount).join(' ');
  
  // Calculate position
  int xPosition = margin.left;
  if (align == PrintAlign.center) {
    xPosition = ((paperSize.width - lastValidWidth) ~/ 2);
  } else if (align == PrintAlign.right) {
    final marginWidth = rtl ? margin.width : margin.left;
    xPosition = paperSize.width - lastValidWidth - marginWidth;
  }

  // Ensure height and draw
  final lineHeight = textFont.lineHeight;
  final totalHeight = lineHeight + (lineHeight ~/ 12);
  _ensureHeight(runningHeight + totalHeight);

  drawString(
    utilImage,
    currentLine,
    font: textFont,
    x: xPosition,
    y: runningHeight,
    color: textColor,
  );
  
  runningHeight += totalHeight;

  // Process remaining text (avoid recursion if possible)
  if (lastValidCount < nonEmptyWords.length) {
    final remainingWords = rtl
        ? nonEmptyWords.sublist(0, nonEmptyWords.length - lastValidCount)
        : nonEmptyWords.sublist(lastValidCount);
    
    if (remainingWords.isNotEmpty) {
      this.text(remainingWords.join(' '), style: style);
    }
  }
}



  /// Draw horizontal line
  void line({int thickness = 1}) {
    _ensureHeight(runningHeight + thickness+15);
    runningHeight += 5;
    fillRect(
      utilImage,
      x1: margin.left,
      x2: paperSize.width - margin.right,
      y1: runningHeight,
      y2: runningHeight + thickness,
      color: textColor,
    );
    runningHeight += thickness+10;
  }

  /// Draw dotted horizontal line
  void dottedLine({int thickness = 1, int dotWidth = 5, int spacing = 3}) {
    _ensureHeight(runningHeight + thickness+15);
    runningHeight += 5;
    int x = margin.left;
    while (x < paperSize.width - margin.right) {
      fillRect(
        utilImage,
        x1: x,
        x2: x + dotWidth,
        y1: runningHeight,
        y2: runningHeight + thickness,
        color: textColor,
      );
      x += dotWidth + spacing;
    }
    runningHeight += thickness+10;
  }

  /// Draw image (resized)
  void image(
    img.Image subImage, {
    int? width,
    int? height,
    PrintAlign align = PrintAlign.left,
  }) {
    final resized = copyResize(
      subImage,
      width: width ?? subImage.width,
      height: height ?? subImage.height,
    );

    _ensureHeight(runningHeight + resized.height + 5);

    int posX;
    final posY = runningHeight;

    if (align == PrintAlign.center) {
      posX = ((paperSize.width - resized.width) / 2).round();
    } else if (align == PrintAlign.right) {
      posX = paperSize.width - resized.width - margin.right;
    } else {
      posX = margin.left;
    }

    img.compositeImage(
      utilImage,
      resized,
      dstX: posX,
      dstY: posY,
      blend: img.BlendMode.direct,
    );
    runningHeight += (resized.height + 5);
  }

  /// Draw QR Code - Optimized to use fillRect instead of nested pixel loops
  void qr(String data, {int qrSize = 150, PrintAlign align = PrintAlign.center}) {
    final qr = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qr);

    final drawQrImage = img.Image(width: qrSize, height: qrSize);
    fill(drawQrImage, color: ColorUint1.rgba(255, 255, 255, 255));

    final moduleCount = qrImage.moduleCount;
    final pixelSize = (qrSize / moduleCount).floor();
    final color = ColorUint1.rgba(0, 0, 0, 255);

    // Optimized: Use fillRect instead of nested pixel loops (10-100x faster)
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(x, y)) {
          final px = x * pixelSize;
          final py = y * pixelSize;
          fillRect(
            drawQrImage,
            x1: px,
            y1: py,
            x2: px + pixelSize,
            y2: py + pixelSize,
            color: color,
          );
        }
      }
    }

    image(drawQrImage, align: align, width: qrSize, height: qrSize);
  }

  void barcode(
    String data, {
    required Barcode barcode,
    int width = 300,
    int height = 120,
    PrintAlign align = PrintAlign.center,
  }) {
    final bcImage = img.Image(width: width, height: height);
    fill(bcImage, color: ColorRgb8(255, 255, 255));
    Barcode.code128();
    drawBarcode(
      bcImage,
      barcode,
      data,
      font: lithos22,
      width: width,
      height: height - 10,
    );
    image(
      bcImage,
      align: align,
      width: width,
      height: height,
    ); // Your image render function
  }

 void row({required List<PrintColumn> columns, int spacing = 10}) {
    if (columns.isEmpty) return; // Early exit
    
    int xPosition = margin.left;
    int totalWidth =
        paperSize.width - margin.width - (spacing * (columns.length - 1));
    int totalRatio = columns.fold(0, (sum, col) => sum + col.flex);

    int maxLines = 0;
    final List<List<String>> allColumnLines = []; // Pre-calculate all lines

    // First pass: Calculate all lines for all columns (optimized)
    for (PrintColumn column in columns) {
      if (column.text.isEmpty) {
        allColumnLines.add(['']);
        continue;
      }
      
      final columnFont = _getFont(column.style, paperSize);
      final columnWidth = (totalWidth * (column.flex / totalRatio)).round();
      
      // Optimized: Use StringBuffer and split once
      final words = column.text.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) {
        allColumnLines.add(['']);
        continue;
      }
      
      List<String> lines = [];
      String currentLine = '';
      
      for (int i = 0; i < words.length; i++) {
        final testLine = currentLine.isEmpty ? words[i] : '$currentLine ${words[i]}';
        final lineWidth = columnFont.getMetrics(testLine).width;
        
        if (lineWidth <= columnWidth) {
          currentLine = testLine;
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
          }
          currentLine = words[i];
        }
      }
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }
      
      if (lines.isEmpty) lines.add('');
      allColumnLines.add(lines);
      if (maxLines < lines.length) {
        maxLines = lines.length;
      }
    }

    // Second pass: Draw all columns
    final columnFont = _getFont(columns.first.style, paperSize);
    _ensureHeight(runningHeight + (maxLines * columnFont.lineHeight));
    final rowYPosition = runningHeight;

    for (int colIdx = 0; colIdx < columns.length; colIdx++) {
      final column = columns[colIdx];
      final lines = allColumnLines[colIdx];
      final columnFont = _getFont(column.style, paperSize);
      final columnWidth = (totalWidth * (column.flex / totalRatio)).round();
      final align = column.style.align;
      
      int tempRunningHeight = rowYPosition;
      
      for (String line in lines) {
        if (line.isEmpty) {
          tempRunningHeight += columnFont.lineHeight + (columnFont.lineHeight ~/ 12);
          continue;
        }
        
        final arabic = isArabic(line);
        final textFont = arabic ? lithos22 : columnFont;
        final shapedLine = arabic ? ShapeArabic.shape(line) : line;
        
        // Cache metrics calculation
        final lineWidth = textFont.getMetrics(shapedLine).width;
        int textXPosition = xPosition;
        
        if (align == PrintAlign.center) {
          textXPosition = xPosition + ((columnWidth - lineWidth) / 2).round();
        } else if (align == PrintAlign.right) {
          textXPosition = xPosition + (columnWidth - lineWidth).round();
        }

        drawString(
          utilImage,
          shapedLine,
          font: textFont,
          x: textXPosition,
          y: tempRunningHeight,
          color: textColor,
        );
        tempRunningHeight += columnFont.lineHeight + (columnFont.lineHeight ~/ 12);
      }

      xPosition += columnWidth + spacing;
    }

    runningHeight += (maxLines * columnFont.lineHeight) + (columnFont.lineHeight ~/ 12);
  }

  void feed({int lines = 1}) {
    _ensureHeight(runningHeight + font.lineHeight + 10);
    runningHeight += (font.lineHeight + 10) * lines;
  }

  /// Get final image as PNG
  Uint8List build1() {
    final finalImage = img.Image(
      width: paperSize.width,
      height: runningHeight,
    );

    for (int y = 0; y < runningHeight; y++) {
      for (int x = 0; x < paperSize.width; x++) {
        finalImage.setPixel(x, y, utilImage.getPixel(x, y));
      }
    }

    return encodePng(finalImage);
  }


Uint8List build() {
  // Use copyCrop for efficient image copying instead of pixel-by-pixel loops
  // This is 10-100x faster than nested loops
  final finalImage = copyCrop(
  utilImage,
  x: 0,
  y: 0,
  width: paperSize.width,
  height: runningHeight,
  );
  return encodePng(finalImage);
}

}

class PrintPaperSize {
  const PrintPaperSize._internal(this.width);
  final int width;
  static const mm58 = PrintPaperSize._internal(372);
  static const mm72 = PrintPaperSize._internal(503);
  static const mm80 = PrintPaperSize._internal(558);
  static const a4 = PrintPaperSize._internal(794);
  static const a3 = PrintPaperSize._internal(1123);

  /// Create a custom PaperSize with a specific width
  factory PrintPaperSize.custom(int width) {
    return PrintPaperSize._internal(width);
  }
}

class PrintTextStyle {
  final PrintFontSize fontSize;
  final PrintAlign align;
  final bool bold;

  const PrintTextStyle({
    this.fontSize = PrintFontSize.small,
    this.align = PrintAlign.left,
    this.bold = false,
  });

  PrintTextStyle copyWith({
    PrintFontSize? fontSize,
    PrintAlign? align,
    bool? bold,
  }) {
    return PrintTextStyle(
      fontSize: fontSize ?? this.fontSize,
      align: align ?? this.align,
      bold: bold ?? this.bold,
    );
  }
}

class PrintColumn {
  final String text;
  final int flex;
  final PrintTextStyle style;

  PrintColumn(this.text, {this.flex = 1, this.style = const PrintTextStyle()});
}

enum PrintAlign { left, center, right }

enum PrintFontSize { small, medium, large }

class PrintMargin {
  final int left;
  final int right;

  const PrintMargin({this.left = 2, this.right = 2});
  int get width => left + right;
}


