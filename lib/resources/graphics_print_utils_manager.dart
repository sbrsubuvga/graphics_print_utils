import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/cupertino.dart';
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
  }) {
    utilImage = img.Image(width: paperSize.width, height: 1000);
    fill(utilImage, color: ColorUint1.rgba(255, 255, 255, 255));
  }

  BitmapFont _getFont(PrintTextStyle style, {String language = 'en'}) {
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

  void text(String text, {PrintTextStyle? style}) {
    BitmapFont textFont = font;
    PrintAlign align = PrintAlign.left;
    if (style != null) {
      textFont = _getFont(style);
      align = style.align;
    }

    int xPosition = margin.left;

    if (align == PrintAlign.center) {
      xPosition = ((paperSize.width - textFont.getMetrics(text).width) / 2)
          .round();
    } else if (align == PrintAlign.right) {
      xPosition =
          (paperSize.width - textFont.getMetrics(text).width - margin.width)
              .round();
    }

    drawString(
      utilImage,
      text,
      font: textFont,
      x: xPosition,
      y: runningHeight,
      color: textColor,
    );
    runningHeight += textFont.lineHeight + 10;
  }

  String _reverseText(String text) {
    return text.split('').reversed.join();
  }

  /// Draw horizontal line
  void line({int thickness = 1}) {
    fillRect(
      utilImage,
      x1: margin.left,
      x2: paperSize.width - margin.right,
      y1: runningHeight,
      y2: runningHeight + thickness,
      color: textColor,
    );
    runningHeight += thickness + 10;
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
        utilImage.setPixel(posX + sx, posY + sy, pixel);
      }
    }
    runningHeight += (resized.height + 10);
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

  /// Draw a row with columns
  void row({required List<PrintColumn> columns, int spacing = 10}) {
    int xPosition = margin.left;
    int totalWidth =
        paperSize.width - margin.width - (spacing * (columns.length - 1));
    int totalRatio = columns.fold(0, (sum, col) => sum + col.flex);

    for (PrintColumn column in columns) {
      int columnWidth = (totalWidth * (column.flex / totalRatio)).round();
      int textXPosition = xPosition;

      if (column.style.align == PrintAlign.center) {
        textXPosition +=
            ((columnWidth - font.getMetrics(column.text).width) / 2).round();
      } else if (column.style.align == PrintAlign.right) {
        textXPosition += (columnWidth - font.getMetrics(column.text).width)
            .round();
      }

      drawString(
        utilImage,
        column.text,
        font: font,
        x: textXPosition,
        y: runningHeight,
        color: textColor,
      );
      xPosition += columnWidth + spacing;
    }

    runningHeight += font.lineHeight + 10;
  }

  void feed({int lines = 1}) {
    runningHeight += (font.lineHeight + 10) * lines;
  }

  /// Get final image as PNG
  Uint8List build() {
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
    this.bold = true,
  });
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
