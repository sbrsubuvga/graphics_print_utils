import 'dart:typed_data';

import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

class GraphicsPrintUtils {
  late img.Image utilImage;
  int runningHeight = 0;
  PrintMargin margin = PrintMargin(left: 5, right: 5);
  final PrintPaperSize paperSize;
  BitmapFont font = arial24;
  final textColor = ColorUint1.rgba(0, 0, 0, 255);

  GraphicsPrintUtils({
    this.paperSize = PrintPaperSize.mm80,
    this.margin = const PrintMargin(),
    PrintTextStyle? style = const PrintTextStyle(),
  }) {
    utilImage = img.Image(width: paperSize.width, height: 1000);
    fill(utilImage, color: ColorUint1.rgba(255, 255, 255, 255));
    if (style != null) {
      font = _getFont(style);
    }
  }

  BitmapFont _getFont(PrintTextStyle style) {
    BitmapFont myFont = arial14;
    switch (style.fontSize) {
      case PrintFontSize.small:
        myFont = arial14;
        break;
      case PrintFontSize.medium:
        myFont = arial24;
        break;
      case PrintFontSize.large:
        myFont = arial48;
        break;
    }
    myFont.bold = style.bold;
    return myFont;
  }

  void _ensureHeight(int requiredHeight) {
    print("requiredHeight: $requiredHeight, current height: ${utilImage.height}");
    if (requiredHeight > utilImage.height) {
      final newHeight = requiredHeight + 1000; // Add extra space to minimize frequent resizing
      print("Resizing utilImage to new height: $newHeight");
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


  void text(String text, {PrintTextStyle? style}) {
    BitmapFont textFont = font;
    PrintAlign align = PrintAlign.left;
    if (style != null) {
      textFont = _getFont(style);
      align = style.align;
    }

    int maxWidth = paperSize.width - margin.width;

    // Find the maximum text that fits in one line
    String currentLine = '';
    for (String word in text.split(' ')) {
      String testLine = currentLine.isEmpty ? word : '$currentLine $word';
      if (textFont.getMetrics(testLine).width <= maxWidth) {
        currentLine = testLine;
      } else {
        break;
      }
    }

    // Draw the current line
    int xPosition = margin.left;
    if (align == PrintAlign.center) {
      xPosition = ((paperSize.width - textFont.getMetrics(currentLine).width) / 2)
          .round();
    } else if (align == PrintAlign.right) {
      xPosition = (paperSize.width - textFont.getMetrics(currentLine).width - margin.width)
          .round();
    }

    _ensureHeight(runningHeight+textFont.lineHeight + 10);
    drawString(
      utilImage,
      currentLine,
      font: textFont,
      x: xPosition,
      y: runningHeight,
      color: textColor,
    );
    runningHeight += textFont.lineHeight + 10;


    // Recursively call the function with the remaining text
    String remainingText = text.substring(currentLine.length).trim();
    if (remainingText.isNotEmpty) {
      this.text(remainingText, style: style);
    }
  }

  /// Draw horizontal line
  void line({int thickness = 1}) {
    _ensureHeight(runningHeight+thickness + 20);
    fillRect(
      utilImage,
      x1: margin.left,
      x2: paperSize.width - margin.right,
      y1: runningHeight,
      y2: runningHeight + thickness,
      color: textColor,
    );
    runningHeight += thickness + 20;

  }

  /// Draw dotted horizontal line
  void dottedLine({int thickness = 1, int dotWidth = 5, int spacing = 3}) {

    _ensureHeight(thickness + 20);
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
    runningHeight += thickness + 20;
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


    _ensureHeight(runningHeight+resized.height + 10);

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
    print("resized.height ${runningHeight}");
    runningHeight += (resized.height + 10);
    print("resized.height ${runningHeight}");
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
      font: arial24,
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
    int totalWidth =paperSize.width - margin.width - (spacing * (columns.length - 1));
    int totalRatio = columns.fold(0, (sum, col) => sum + col.flex);



    int maxLines=0;
    for (PrintColumn column in columns) {
      int columnWidth = (totalWidth * (column.flex / totalRatio)).round();
      int textXPosition = xPosition;
      final rowYPosition = runningHeight;

      // Split text into lines that fit within the column width
      List<String> lines = [];
      String currentLine = '';
      for (String word in column.text.split(' ')) {
        String testLine = currentLine.isEmpty ? word : '$currentLine $word';
        if (font.getMetrics(testLine).width <= columnWidth) {
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

      if(maxLines<lines.length){
        maxLines=lines.length;
      }

      _ensureHeight(runningHeight + (maxLines*font.lineHeight) + 10);

      // Draw each line within the column
      for (String line in lines) {
        if (column.style.align == PrintAlign.center) {
          textXPosition = xPosition +
              ((columnWidth - font.getMetrics(line).width) / 2).round();
        } else if (column.style.align == PrintAlign.right) {
          textXPosition = xPosition +
              (columnWidth - font.getMetrics(line).width).round();
        }

        drawString(
          utilImage,
          line,
          font: font,
          x: textXPosition,
          y: tempRunningHeight,
          color: textColor,
        );
        tempRunningHeight+=font.lineHeight;

      }

      xPosition += columnWidth + spacing;
    }

    runningHeight += (maxLines*font.lineHeight)+10;
  }

  void feed({int lines = 1}) {
    _ensureHeight(runningHeight+font.lineHeight + 10);
    runningHeight += (font.lineHeight + 10) * lines;
  }

  /// Get final image as PNG
  Uint8List build() {
    final finalImage = copyCrop(
      utilImage,
      x: 0,
      y: 0,
      width: paperSize.width,
      height: runningHeight, // Adjust height as needed
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
    this.fontSize = PrintFontSize.medium,
    this.align = PrintAlign.left,
    this.bold = true,
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
