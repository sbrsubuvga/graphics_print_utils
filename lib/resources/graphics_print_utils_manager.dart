import 'dart:typed_data';

import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/services.dart';
import 'package:graphics_print_utils/fonts/arabic_48.dart';
import 'package:graphics_print_utils/fonts/shape_arabic.dart';
import 'package:image/image.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import '../fonts/arabic_24.dart';

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
    utilImage = img.Image(width: paperSize.width, height: 5000);
    fill(utilImage, color: ColorUint1.rgba(255, 255, 255, 255));
    if (style != null) {
      font = _getFont(style);
    }
  }

  BitmapFont _getFont(PrintTextStyle style, {bool isArabic = false}) {
    BitmapFont myFont = arial14;
    switch (style.fontSize) {
      case PrintFontSize.small:
        if (isArabic) {
          myFont = arial14;
        } else {
          myFont = arial14;
        }
        break;
      case PrintFontSize.medium:
        if (isArabic) {
          myFont = arabic24;
        } else {
          myFont = arial24;
        }
        break;
      case PrintFontSize.large:
        if (isArabic) {
          myFont = arabic48;
        } else {
          myFont = arial48;
        }
        break;
    }
    myFont.bold = style.bold;
    return myFont;
  }

  //
  // void _ensureHeight(int requiredHeight) {
  //   if (requiredHeight > utilImage.height) {
  //     final newHeight =
  //         requiredHeight +
  //         5000; // Add extra space to minimize frequent resizing
  //
  //     final resizedImage = img.Image(width: utilImage.width, height: newHeight);
  //     fill(resizedImage, color: ColorUint1.rgba(255, 255, 255, 255));
  //     // Copy the content of the old image to the new resized image
  //     for (int y = 0; y < utilImage.height; y++) {
  //       for (int x = 0; x < utilImage.width; x++) {
  //         resizedImage.setPixel(x, y, utilImage.getPixel(x, y));
  //       }
  //     }
  //     utilImage = resizedImage;
  //   }
  // }


  void _ensureHeight(int requiredHeight) {
    if (requiredHeight > utilImage.height) {
      final newHeight = requiredHeight + 5000;

      final newImage = Image(
        width: utilImage.width,
        height: newHeight,
        format: utilImage.format,
        numChannels: utilImage.numChannels,
        withPalette: utilImage.hasPalette,
        palette: utilImage.palette,
      );

      // Fill new image with background color (optional)
      newImage.clear( ColorUint1.rgba(255, 255, 255, 255));

      // Copy old image pixels to new image
      for (int y = 0; y < utilImage.height; y++) {
        for (int x = 0; x < utilImage.width; x++) {
          final pixel = utilImage.getPixel(x, y);
          newImage.setPixel(x, y, pixel);
        }
      }
      utilImage = newImage;
    }
  }

  // void text(String text, {PrintTextStyle? style}) {
  //   BitmapFont textFont = font;
  //   PrintAlign align = PrintAlign.left;
  //   if (style != null) {
  //     textFont = _getFont(style);
  //     align = style.align;
  //   }
  //
  //   int maxWidth = paperSize.width - margin.width;
  //
  //    final lines=  text.split('\n');
  //     if(lines.length>1){
  //      for (String line in lines) {
  //        this.text(line, style: style);
  //      }
  //     }
  //     else {
  //       // Find the maximum text that fits in one line
  //       String currentLine = '';
  //       for (String word in text.split(' ')) {
  //         String testLine = currentLine.isEmpty ? word : '$currentLine $word';
  //         if (textFont
  //             .getMetrics(testLine)
  //             .width <= maxWidth) {
  //           currentLine = testLine;
  //         }
  //         else {
  //           break;
  //         }
  //       }
  //
  //       // Draw the current line
  //       int xPosition = margin.left;
  //       if (align == PrintAlign.center) {
  //         xPosition = ((paperSize.width - textFont
  //             .getMetrics(currentLine)
  //             .width) / 2)
  //             .round();
  //       } else if (align == PrintAlign.right) {
  //         xPosition = (paperSize.width - textFont
  //             .getMetrics(currentLine)
  //             .width - margin.width)
  //             .round();
  //       }
  //
  //       _ensureHeight(runningHeight + textFont.lineHeight + 10);
  //       drawString(
  //         utilImage,
  //         currentLine,
  //         font: textFont,
  //         x: xPosition,
  //         y: runningHeight,
  //         color: textColor,
  //       );
  //       runningHeight += textFont.lineHeight + 10;
  //
  //
  //       // Recursively call the function with the remaining text
  //       String remainingText = text.substring(currentLine.length).trim();
  //       if (remainingText.isNotEmpty) {
  //         this.text(remainingText, style: style);
  //       }
  //     }
  // }

  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }

  // // Assuming this is part of a class that has access to the members mentioned above.
  // void text(String text, {PrintTextStyle? style}) async {
  //   img.BitmapFont textFont = font;
  //   PrintAlign align = PrintAlign.left;
  //   bool arabic = isArabic(text);
  //   if (arabic) {
  //     textFont = arabic24;
  //     // Step 1: Shape the Arabic characters into their presentation forms.
  //     // The output of ShapeArabic.shape is in logical order (LTR sequence of glyphs).
  //     text = ShapeArabic.shape(text);
  //   }
  //
  //   if (style != null) {
  //     textFont = _getFont(
  //       style,
  //       isArabic: arabic,
  //     ); // Make sure _getFont returns a font that handles RTL if you use it
  //     align = style.align;
  //   }
  //
  //   // final fontZipFile2 = await rootBundle.load('assets/noto_serif_24.zip').then((byteData) => byteData.buffer.asUint8List());
  //   // textFont = img.BitmapFont.fromZip(fontZipFile2);
  //
  //   int maxWidth = paperSize.width - margin.width;
  //
  //   String currentLine = '';
  //   List<String> words = text
  //       .split(' ')
  //       .where((e) => e.isNotEmpty)
  //       .toList(); // This assumes space as word delimiter
  //   for (int i = words.length - 1; i >= 0; i--) {
  //     // Iterate words in reverse logical order for RTL line breaking
  //     String word = words[i];
  //     String testLine = currentLine.isEmpty
  //         ? word
  //         : '$word $currentLine'; // Build line from right
  //     if (textFont.getMetrics(testLine).width <= maxWidth) {
  //       currentLine = testLine;
  //     } else {
  //       break; // Line is full
  //     }
  //   }
  //
  //   // After determining 'currentLine' in logical order (reading from right to left visually)
  //   // It's crucial that `drawString` correctly handles this logical order for RTL display.
  //
  //   // Draw the current line
  //   int xPosition = margin.left;
  //   if (align == PrintAlign.center) {
  //     xPosition =
  //         ((paperSize.width - textFont.getMetrics(currentLine).width) / 2)
  //             .round();
  //   } else if (align == PrintAlign.right) {
  //     // For RTL text aligned right, the text starts at (paperSize.width - text width - margin.right).
  //     // The current align.right logic for xPosition is correct if getMetrics gives logical width.
  //     xPosition =
  //         (paperSize.width -
  //                 textFont.getMetrics(currentLine).width -
  //                 margin.width)
  //             .round();
  //   }
  //
  //   _ensureHeight(runningHeight + textFont.lineHeight + 10);
  //   drawString(
  //     utilImage,
  //     currentLine, // Pass the shaped text in its logical order
  //     font: textFont,
  //     x: xPosition,
  //     y: runningHeight,
  //     color: textColor,
  //   );
  //   runningHeight += textFont.lineHeight + 10;
  //
  //   // Recursively call the function with the remaining text
  //   // This part needs to be careful with indexing if you adapted line breaking for RTL.
  //   // Simplest is to rejoin the words not used and pass them to the recursive call.
  //   List<String> remainingWords = [];
  //   int currentLineWordCount = currentLine.split(' ').length;
  //   for (int i = 0; i < words.length - currentLineWordCount; i++) {
  //     remainingWords.add(words[i]); // Words that were not put into currentLine
  //   }
  //   String remainingText = remainingWords.join(' ');
  //
  //   if (remainingText.isNotEmpty) {
  //     // Note: 'this.text' implies a method named 'text' in the same class.
  //     // If 'this.text' means the original 'void text(String text, ...)'
  //     // then it will re-shape the text, which is redundant.
  //     // Ensure the recursive call doesn't re-shape already shaped text.
  //     // You might need a `textArabicShaped(String shapedText, ...)` for recursion.
  //     // For now, assuming you want to re-shape, which is inefficient but functionally ok if `text`
  //     // doesn't call shape again.
  //     this.text(remainingText, style: style);
  //   }
  // }

  void text(String text, {PrintTextStyle? style}) {
    bool rtl = isArabic(text); // Determine direction
    img.BitmapFont textFont = font;
    PrintAlign align = PrintAlign.left;

    if (rtl) {
      textFont = arabic24;
      text = ShapeArabic.shape(text); // Shape once
    }

    if (style != null) {
      textFont = _getFont(style, isArabic: rtl);
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
    runningHeight += textFont.lineHeight;

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
    _ensureHeight(runningHeight + thickness+5);
    fillRect(
      utilImage,
      x1: margin.left,
      x2: paperSize.width - margin.right,
      y1: runningHeight,
      y2: runningHeight + thickness,
      color: textColor,
    );
    runningHeight += thickness+5;
  }

  /// Draw dotted horizontal line
  void dottedLine({int thickness = 1, int dotWidth = 5, int spacing = 3}) {
    _ensureHeight(thickness + 5);
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
    runningHeight += thickness + 5;
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
    int totalWidth =
        paperSize.width - margin.width - (spacing * (columns.length - 1));
    int totalRatio = columns.fold(0, (sum, col) => sum + col.flex);

    int maxLines = 0;
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

      if (maxLines < lines.length) {
        maxLines = lines.length;
      }

      _ensureHeight(runningHeight + (maxLines * font.lineHeight) );
      img.BitmapFont textFont = font;
      PrintAlign align = PrintAlign.left;
      // Draw each line within the column
      for (String line in lines) {
        final arabic = isArabic(line);
        if (arabic) {
          textFont = arabic24;
          // Step 1: Shape the Arabic characters into their presentation forms.
          // The output of ShapeArabic.shape is in logical order (LTR sequence of glyphs).
          line = ShapeArabic.shape(line);
        }

        textFont = _getFont(
          column.style,
          isArabic: arabic,
        ); // Make sure _getFont returns a font that handles RTL if you use it
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
        tempRunningHeight += font.lineHeight;
      }

      xPosition += columnWidth + spacing;
    }

    runningHeight += (maxLines * font.lineHeight) ;
  }

  void feed({int lines = 1}) {
    _ensureHeight(runningHeight + font.lineHeight + 10);
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
