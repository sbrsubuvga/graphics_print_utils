import 'dart:typed_data';

import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/services.dart';
import 'package:graphics_print_utils/fonts/lithos_18.dart';
import 'package:graphics_print_utils/fonts/lithos_18_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_22_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_24.dart';
import 'package:graphics_print_utils/fonts/lithos_24_bold.dart';
import 'package:graphics_print_utils/fonts/lithos_26.dart';
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

  GraphicsPrintUtils({
    this.paperSize = PrintPaperSize.mm80,
    this.margin = const PrintMargin(),
    PrintTextStyle? style = const PrintTextStyle(),
  }) {
    utilImage = img.Image(width: paperSize.width, height: 10000);
    fill(utilImage, color: ColorUint1.rgba(255, 255, 255, 255));
    if (style != null) {
      font = _getFont(style, paperSize);
    }
  }

  BitmapFont _getFont(PrintTextStyle style,PrintPaperSize paperSize){
    if(paperSize == PrintPaperSize.mm58){
      return _getFont2(style);
    }
    else{
      return _getFont3(style);
    }
  }

  BitmapFont _getFont3(PrintTextStyle style) {
    BitmapFont myFont = lithos22;
    switch (style.fontSize) {
      case PrintFontSize.small:
        myFont = lithos22;
        if(style.bold){
          myFont=lithos22Bold;
        }
        break;
      case PrintFontSize.medium:
        myFont = lithos24;
        if(style.bold){
          myFont=lithos24Bold;
        }
        break;
      case PrintFontSize.large:
        myFont = lithos34Bold;
        if(style.bold){
          myFont=lithos40Bold;
        }
        break;
    }
    return myFont;
  }
  
  BitmapFont _getFont2(PrintTextStyle style) {
    BitmapFont myFont = lithos22;
    switch (style.fontSize) {
      case PrintFontSize.small:
        myFont = lithos18;
        if(style.bold){
          myFont=lithos18Bold;
        }
        break;
      case PrintFontSize.medium:
        myFont = lithos22;
        if(style.bold){
          myFont=lithos22Bold;
        }
        break;
      case PrintFontSize.large:
        myFont = lithos22Bold;
        if(style.bold){
          myFont=lithos26Bold;
        }
        break;
    }
    return myFont;
  }

  void _ensureHeight(int requiredHeight) {
    if (requiredHeight > utilImage.height) {
      final newHeight =
          requiredHeight +
          10000; // Add extra space to minimize frequent resizing

      final resizedImage = img.Image(width: utilImage.width, height: newHeight);
      fill(resizedImage, color: ColorUint1.rgba(255, 255, 255, 255));
      // Copy the content of the old image to the new resized image
      for (int y = 0; y < utilImage.height; y++) {
        for (int x = 0; x < utilImage.width; x++) {
          resizedImage.setPixel(x, y, utilImage.getPixel(x, y));
        }
      }
      utilImage = resizedImage;
    }
  }


  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }


  void text(String text, {PrintTextStyle? style}) {
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
    List<String> words = text.split(' ').where((e) => e.isNotEmpty).toList();
    List<String> currentLineWords = [];

    if (rtl) {
      for (int i = words.length - 1; i >= 0; i--) {
        String tempLine = [...words.sublist(i)].reversed.join(' ');
        int lineWidth = textFont.getMetrics(tempLine).width;
        if (lineWidth <= maxWidth) {
          currentLineWords.insert(0, words[i]);
        } else {
          break;
        }
      }
    } else {
      for (String word in words) {
        String tempLine = (currentLineWords + [word]).join(' ');
        int lineWidth = textFont.getMetrics(tempLine).width;
        if (lineWidth <= maxWidth) {
          currentLineWords.add(word);
        } else {
          break;
        }
      }
    }

    String currentLine = currentLineWords.join(' ');
    int textWidth = textFont.getMetrics(currentLine).width;

    int xPosition = margin.left;
    if (align == PrintAlign.center) {
      xPosition = ((paperSize.width - textWidth) / 2).round();
    } else if (align == PrintAlign.right) {
      final marginWidth=rtl?margin.width:margin.left;

      xPosition = (paperSize.width - textWidth - marginWidth).round();
    }

    _ensureHeight(runningHeight + textFont.lineHeight);

    drawString(
      utilImage,
      currentLine,
      font: textFont,
      x: xPosition,
      y: runningHeight,
      color: textColor,
    );
    runningHeight += textFont.lineHeight+(textFont.lineHeight~/12);

    // Remaining text
    int usedCount = currentLineWords.length;
    List<String> remainingWords = rtl
        ? words.sublist(0, words.length - usedCount)
        : words.sublist(usedCount);
    if (remainingWords.isNotEmpty) {
      this.text(remainingWords.join(' '), style: style);
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

    for (int sy = 0; sy < resized.height; sy++) {
      for (int sx = 0; sx < resized.width; sx++) {
        final pixel = resized.getPixel(sx, sy).current;

        // Ensure the pixel coordinates are within bounds
        final targetX = posX + sx;
        final targetY = posY + sy;
        if (targetX >= 0 &&
            targetX < utilImage.width &&
            targetY >= 0 &&
            targetY < utilImage.height) {
          utilImage.setPixel(targetX, targetY, pixel);
        }
      }
    }
    runningHeight += (resized.height + 5);
  }

  /// Draw QR Code
  qr(String data, {int qrSize = 150, PrintAlign align = PrintAlign.center}) {
    final qr = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qr);

    final drawQrImage = img.Image(width: qrSize, height: qrSize);
    fill(drawQrImage, color: ColorUint1.rgba(255, 255, 255, 255));

    final moduleCount = qrImage.moduleCount;
    final pixelSize = (qrSize / moduleCount).floor();

    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        final isDark = qrImage.isDark(x, y);
        final color = ColorUint1.rgba(0, 0, 0, 255);
        if (isDark) {
          for (int dy = 0; dy < pixelSize; dy++) {
            for (int dx = 0; dx < pixelSize; dx++) {
              final px = x * pixelSize + dx;
              final py = y * pixelSize + dy;

              if (px < drawQrImage.width && py < drawQrImage.height) {
                drawQrImage.setPixel(px, py, color);
              }
            }
          }
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
    int xPosition = margin.left;
    int totalWidth =
        paperSize.width - margin.width - (spacing * (columns.length - 1));
    int totalRatio = columns.fold(0, (sum, col) => sum + col.flex);

    int maxLines = 0;
    img.BitmapFont columnFont = font;

    for (PrintColumn column in columns) {
      columnFont = _getFont(column.style, paperSize);
      int columnWidth = (totalWidth * (column.flex / totalRatio)).round();
      int textXPosition = xPosition;
      final rowYPosition = runningHeight;

      // Split text into lines that fit within the column width
      List<String> lines = [];
      String currentLine = '';
      for (String word in column.text.split(' ')) {
        String testLine = currentLine.isEmpty ? word : '$currentLine $word';
        if (columnFont.getMetrics(testLine).width <= columnWidth) {
          currentLine = testLine;
        } else {
          lines.add(currentLine);
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }

      int tempRunningHeight = rowYPosition;

      if (maxLines < lines.length) {
        maxLines = lines.length;
      }

      _ensureHeight(runningHeight + (maxLines * columnFont.lineHeight) );
      img.BitmapFont textFont = columnFont;
      PrintAlign align = PrintAlign.left;
      // Draw each line within the column
      for (String line in lines) {
        final arabic = isArabic(line);
        if (arabic) {
          textFont = lithos22; // Use Arabic font for RTL text
          // Step 1: Shape the Arabic characters into their presentation forms.
          // The output of ShapeArabic.shape is in logical order (LTR sequence of glyphs).
          line = ShapeArabic.shape(line);
        } else {
          textFont = _getFont(
              column.style, paperSize); // Make sure _getFont returns a font that handles RTL if you use it
        }
        align = column.style.align;

        if (align == PrintAlign.center) {
          textXPosition =
              xPosition +
              ((columnWidth - textFont.getMetrics(line).width) / 2).round();
        } else if (align == PrintAlign.right) {
          textXPosition =
              xPosition + (columnWidth - textFont.getMetrics(line).width).round();
        }

        drawString(
          utilImage,
          line,
          font: textFont,
          x: textXPosition,
          y: tempRunningHeight,
          color: textColor,
        );
        tempRunningHeight += columnFont.lineHeight+(columnFont.lineHeight~/12);
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
  Uint8List build() {
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
