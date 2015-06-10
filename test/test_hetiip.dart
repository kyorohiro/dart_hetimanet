import 'package:unittest/unittest.dart' as unit;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

void main() {
  unit.group("v4", () {
    unit.test("127.0.255.1", () {
      unit.expect(HetiIP.toIPString([127, 0, 255, 1]), "127.0.255.1");
    });
    unit.test("127.0.255.1", () {
      unit.expect(HetiIP.toRawIP("127.0.255.1"), [127, 0, 255, 1]);
    });
  });
  
  unit.group("v6", () {
    unit.test("2001:db8:20:3:1000:100:20:3", () {
      unit.expect(
          HetiIP.toIPString([0x20,0x01,0x0d,0xb8, 0x00,0x20, 0x00,0x03, 0x10,0x00, 0x01,0x00, 0x00,0x20, 0x00,0x03]),
          "2001:db8:20:3:1000:100:20:3");
    });
    
    unit.test("2001:db8:20:3:1000:100:20:3", () {
      unit.expect(
          HetiIP.toRawIP("2001:db8:20:3:1000:100:20:3"),
          [0x20,0x01,0x0d,0xb8, 0x00,0x20, 0x00,0x03, 0x10,0x00, 0x01,0x00, 0x00,0x20, 0x00,0x03]
          );
    });
  });
}
