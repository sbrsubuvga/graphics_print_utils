import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart' hide Barcode;
import 'package:graphics_print_utils/graphics_print.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List pngImage = Uint8List.fromList([]);
  @override
  void initState() {
    initialize();
    super.initState();
  }

  initialize()  async{
    final fontZipLithos_20= await rootBundle.load('assets/lithos_22.zip').then((byteData) => byteData.buffer.asUint8List());
    // Clipboard.setData(ClipboardData(text: fontZipLithos_20.toString()));
    // final chFont = img.BitmapFont.fromZip(fontZipLithos_20);
    pngImage =  drawEscImage();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app', style: TextStyle()),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                if (pngImage.isEmpty) {
                  return SizedBox();
                } else {
                  return Image.memory(pngImage);
                }
              },
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 60,
          child: TextButton(
            onPressed: () async {
              final profile = await CapabilityProfile.load();
              final generator = Generator(PaperSize.mm80, profile);
              List<int> bytes = generator.image(img.decodeImage(pngImage)!);

              /// You can use the bytes to print using your printer
            },
            child: Text(
              'Generate Printing Bytes',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  drawEscImage()  {
    final now1=DateTime.now();
    print("*******************start ${now1}");
    GraphicsPrintUtils escImageUtil = GraphicsPrintUtils(
      paperSize: PrintPaperSize.mm80,
      margin: PrintMargin(left: 10, right: 10),
    );
    // Add store name and header
    escImageUtil.feed(lines: 1);
    escImageUtil.text(
      "SuperMart",
      style: PrintTextStyle(
        fontSize: PrintFontSize.large,
        align: PrintAlign.center,
        bold: true,
      ),
    );
    escImageUtil.text(
      "123 Main Street, Suite 456, Building 7, Business District, City, State, ZIP, Country, Near Central Park, Opposite to ABC Mall, Landmark XYZ",
      style: PrintTextStyle(
        fontSize: PrintFontSize.small,
        align: PrintAlign.center,
      ),
    );
    escImageUtil.text(
      "City, State, ZIP",
      style: PrintTextStyle(
        fontSize: PrintFontSize.small,
        align: PrintAlign.center,
      ),
    );
    escImageUtil.text(
      "Tel: (123) 456-7890",
      style: PrintTextStyle(
        fontSize: PrintFontSize.small,
        align: PrintAlign.center,
      ),
    );

    // Add itemized list
    // escImageUtil.row(
    //   columns: [
    //     PrintColumn('SL', flex: 4,style:PrintTextStyle(
    //         align: PrintAlign.left
    //     )),
    //     PrintColumn('Item', flex: 6,style:PrintTextStyle(
    //         align: PrintAlign.left
    //     )),
    //     PrintColumn('QTY', flex: 5,style:PrintTextStyle(
    //       align: PrintAlign.left,
    //      )
    //     ),
    //     PrintColumn('RATE', flex: 6,style:PrintTextStyle(
    //         align: PrintAlign.left
    //     )
    //     ),
    //     PrintColumn('AMOUNT', flex: 9,style:PrintTextStyle(
    //         align: PrintAlign.left
    //     )
    //     ),
    //   ],
    //   spacing: 2
    // );
    escImageUtil.line();


    // Add itemized list
    escImageUtil.row(
      columns: [
        PrintColumn('Item', flex: 4),
        PrintColumn(
          'Qty',
          flex: 1,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
        PrintColumn(
          'Price',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.line();
    escImageUtil.row(
      columns: [
        PrintColumn('Apples', flex: 4),
        PrintColumn(
          '2',
          flex: 1,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
        PrintColumn(
          '\$3.00',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.dottedLine();
    escImageUtil.row(
      columns: [
        PrintColumn('قيمة', flex: 4),
        PrintColumn(
          '2',
          flex: 1,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
        PrintColumn(
          '\$3.00',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.dottedLine();
    escImageUtil.row(
      columns: [
        PrintColumn('Bananas  ', flex: 4),
        PrintColumn(
          '1',
          flex: 1,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
        PrintColumn(
          '\$1.50',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.dottedLine();
    escImageUtil.row(
      columns: [
        PrintColumn('Milk', flex: 4),
        PrintColumn(
          '1',
          flex: 1,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
        PrintColumn(
          '\$2.50',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.line();

    // Add totals
    escImageUtil.row(
      columns: [
        PrintColumn('Subtotal', flex: 6),
        PrintColumn(
          '\$7.00',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.row(
      columns: [
        PrintColumn('Tax', flex: 6),
        PrintColumn(
          '\$0.50',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right),
        ),
      ],
      spacing: 10,
    );
    escImageUtil.row(
      columns: [
        PrintColumn('Total', flex: 6, style: PrintTextStyle(bold: true)),
        PrintColumn(
          '\$7.50',
          flex: 2,
          style: PrintTextStyle(align: PrintAlign.right, bold: true),
        ),
      ],
      spacing: 10,
    );

    escImageUtil.line();

    // Add QR code for receipt verification
    escImageUtil.text(
      "Scan for Receipt",
      style: PrintTextStyle(align: PrintAlign.center),
    );
    escImageUtil.qr('https://example.com/receipt/12345');

    escImageUtil.text(
      "Scan for invoice",
      style: PrintTextStyle(align: PrintAlign.center),
    );
    escImageUtil.barcode('1259854', barcode: Barcode.code128());

    // Add footer
    escImageUtil.text(
      "Thank you for shopping!",
      style: PrintTextStyle(align: PrintAlign.center),
    );
    escImageUtil.text(
      "Visit us again!",
      style: PrintTextStyle(align: PrintAlign.center),
    );

    escImageUtil.text(
      "¡Gracias por comprar con nosotros!", // Spanish: Thank you for shopping with us!", // Spanish: Thank you for shopping with us!
      style: PrintTextStyle(align: PrintAlign.center),
    );

    // final fontZipCh = await rootBundle.load('assets/ch_24_ch.zip').then((byteData) => byteData.buffer.asUint8List());
    // final chFont = img.BitmapFont.fromZip(fontZipCh);
    // escImageUtil.textArabic(
    //   "感谢您的光临！", // Chinese: Thank you for shopping with us!
    //   chFont,
    //   style: PrintTextStyle(
    //     fontSize: PrintFontSize.small,
    //     align: PrintAlign.center,
    //   ),
    // );
    escImageUtil.text(
      "Merci pour vos achats !", // French: Thank you for shopping with us!
      style: PrintTextStyle(align: PrintAlign.center),
    );
    escImageUtil.text(
      "Bedankt voor uw aankoop!", // Dutch: Thank you for shopping with us!
      style: PrintTextStyle(align: PrintAlign.center),
    );

    // final fontZipFile2 = await rootBundle.load('assets/noto_serif_48.zip').then((byteData) => byteData.buffer.asUint8List());
    //    final arbicFont = img.BitmapFont.fromZip(fontZipFile2);

    // print(fontZipFile2);
    escImageUtil.text(
      "   السلام عليكم  ", // Arabic: Peace be upon you!//لسلام عليكم
      style: PrintTextStyle(align: PrintAlign.center),
    );
    escImageUtil.text(
      "مرحباً بالعالم", // Arabic: Peace be upon you!
      style: PrintTextStyle(align: PrintAlign.center),
    );

    escImageUtil.text(
      "قيمة", // Arabic: Peace be upon you!
      style: PrintTextStyle(align: PrintAlign.right),
    );


    escImageUtil.feed(lines: 1);
    var bytes = escImageUtil.build();
    final now2=DateTime.now();
    print("*******************end ${now2}");
    print("*******************end ${now2.difference(now1)}");

    return bytes;
  }
}
