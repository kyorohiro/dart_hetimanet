library hetimanet.util;

class HetiIP {
  static List<int> toRawIP(String ip) {
    List rawIP = [];
    if (ip.contains(".")) {
      // ip v4
      List<String> v = ip.split(".");
      if (v.length < 4) {
        throw new Exception();
      }
      rawIP.add(int.parse(v[0]));
      rawIP.add(int.parse(v[1]));
      rawIP.add(int.parse(v[2]));
      rawIP.add(int.parse(v[3]));
    } else if (ip.contains(":")) {
      // ip v6
      List<String> v = ip.split(":");
      rawIP.addAll(_toIP4RawPart(int.parse(v[0],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[1],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[2],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[3],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[4],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[5],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[6],radix:16)));
      rawIP.addAll(_toIP4RawPart(int.parse(v[7],radix:16)));
    } else {
      throw new Exception();
    }
    return rawIP;
  }

  static List<int> _toIP4RawPart(int v) {
    List<int> ret = [];
    ret.add(0xff & (v >> 8));
    ret.add(0xff & (v));
    return ret;
  }

  static String toIPString(List<int> rawIP) {
    if (rawIP.length == 4) {
      return "${rawIP[0].toUnsigned(8)}.${rawIP[1].toUnsigned(8)}.${rawIP[2].toUnsigned(8)}.${rawIP[3].toUnsigned(8)}";
    } else if (rawIP.length == 16) {
      return "${_toIP6Part(rawIP[0],rawIP[1])}" +
          ":" +
          "${_toIP6Part(rawIP[2],rawIP[3])}" +
          ":" +
          "${_toIP6Part(rawIP[4],rawIP[5])}" +
          ":" +
          "${_toIP6Part(rawIP[6],rawIP[7])}" +
          ":" +
          "${_toIP6Part(rawIP[8],rawIP[9])}" +
          ":" +
          "${_toIP6Part(rawIP[10],rawIP[11])}" +
          ":" +
          "${_toIP6Part(rawIP[12],rawIP[13])}" +
          ":" +
          "${_toIP6Part(rawIP[14],rawIP[15])}";
    } else {
      throw new Exception();
    }
  }

  static String _toIP6Part(int a, int b) {
    String aa = a.toUnsigned(8).toRadixString(16);
    if(aa == "0") {
      aa = "";
    }
    String bb = b.toUnsigned(8).toRadixString(16);
    if (bb.length == 1&&aa.length != 0) {
      bb = "0" + bb;
    }
    return "${aa}${bb}";
  }
}
