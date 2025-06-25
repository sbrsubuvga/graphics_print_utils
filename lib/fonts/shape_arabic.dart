
// ﺍﺎﺏﺑﺒﺖﺕﺗﺘﺙﺛﺜﺚﺝﺟﺠﺞﺡﺣﺤﺢﺥﺧﺨﺦﺩﺪﺫﺬﺭﺮﺯﺰﺱﺳﺴﺲﺵﺷﺸﺶﺹﺻﺼﺺﺽﺿﻀﺾﻁﻄﻂﻅﻇﻈﻆﻉﻋﻌﻊﻍﻏﻐﻎﻑﻓﻔﻒﻕﻗﻘﻖﻙﻛﻜﻚﻝﻟﻠﻞﻡﻣﻤﻢﻥﻧﻨﻦﻩﻫﻬﻪﻭﻮﻱﻳﻴﻲ



class ShapeArabic {
  static const Map<int, List<int>> _shapingTable = {
    0x0627: [0xFE8D, 0xFE8E], // ALEF
    0x0628: [0xFE8F, 0xFE91, 0xFE92, 0xFE90], // BEH
    0x062A: [0xFE95, 0xFE97, 0xFE98, 0xFE96], // TEH
    0x062B: [0xFE99, 0xFE9B, 0xFE9C, 0xFE9A], // THEH
    0x062C: [0xFE9D, 0xFE9F, 0xFEA0, 0xFE9E], // JEEM
    0x062D: [0xFEA1, 0xFEA3, 0xFEA4, 0xFEA2], // HAH
    0x062E: [0xFEA5, 0xFEA7, 0xFEA8, 0xFEA6], // KHAH
    0x062F: [0xFEA9, 0xFEAA], // DAL
    0x0630: [0xFEAB, 0xFEAC], // THAL
    0x0631: [0xFEAD, 0xFEAE], // REH
    0x0632: [0xFEAF, 0xFEB0], // ZAIN
    0x0633: [0xFEB1, 0xFEB3, 0xFEB4, 0xFEB2], // SEEN
    0x0634: [0xFEB5, 0xFEB7, 0xFEB8, 0xFEB6], // SHEEN
    0x0635: [0xFEB9, 0xFEBB, 0xFEBC, 0xFEBA], // SAD
    0x0636: [0xFEBD, 0xFEBF, 0xFEC0, 0xFEBE], // DAD
    0x0637: [0xFEC1, 0xFEC3, 0xFEC4, 0xFEC2], // TAH
    0x0638: [0xFEC5, 0xFEC7, 0xFEC8, 0xFEC6], // ZAH
    0x0639: [0xFEC9, 0xFECB, 0xFECC, 0xFECA], // AIN
    0x063A: [0xFECD, 0xFECF, 0xFED0, 0xFECE], // GHAIN
    0x0641: [0xFED1, 0xFED3, 0xFED4, 0xFED2], // FEH
    0x0642: [0xFED5, 0xFED7, 0xFED8, 0xFED6], // QAF
    0x0643: [0xFED9, 0xFEDB, 0xFEDC, 0xFEDA], // KAF
    0x0644: [0xFEDD, 0xFEDF, 0xFEE0, 0xFEDE], // LAM
    0x0645: [0xFEE1, 0xFEE3, 0xFEE4, 0xFEE2], // MEEM
    0x0646: [0xFEE5, 0xFEE7, 0xFEE8, 0xFEE6], // NOON
    0x0647: [0xFEE9, 0xFEEB, 0xFEEC, 0xFEEA], // HEH
    0x0648: [0xFEED, 0xFEEE], // WAW
    0x0649: [0xFEEF, 0xFEF0], // ALEF MAKSURA
    0x064A: [0xFEF1, 0xFEF3, 0xFEF4, 0xFEF2], // YEH
    0x0629: [0xFE93, 0xFE94], // TEH MARBUTA
  };

  static bool _canConnectBefore(int codeUnit) {
    return _shapingTable[codeUnit]?.length == 4;
  }

  static bool _canConnectAfter(int codeUnit) {
    return _shapingTable.containsKey(codeUnit);
  }

  static String shape(String input) {
    final runes = input.runes.toList();
    final shaped = <int>[];

    for (int i = 0; i < runes.length; i++) {
      final current = runes[i];

      final int? prev = i > 0 ? runes[i - 1] : null;
      final int? next = i < runes.length - 1 ? runes[i + 1] : null;

      final bool connectBefore = prev != null && _canConnectBefore(prev) && _canConnectAfter(current);
      final bool connectAfter = next != null && _canConnectAfter(next);

      final forms = _shapingTable[current];

      if (forms != null) {
        int shapedChar;
        if (forms.length == 2) {
          shapedChar = connectBefore ? forms[1] : forms[0];
        } else {
          if (!connectBefore && !connectAfter) {
            shapedChar = forms[0]; // Isolated
          } else if (!connectBefore && connectAfter) {
            shapedChar = forms[1]; // Initial
          } else if (connectBefore && connectAfter) {
            shapedChar = forms[2]; // Medial
          } else {
            shapedChar = forms[3]; // Final
          }
        }
        shaped.add(shapedChar);
      } else {
        shaped.add(current); // Leave unchanged
      }
    }

    return String.fromCharCodes(shaped.reversed);
  }
}
