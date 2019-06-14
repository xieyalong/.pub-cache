import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Half', () {
     test('Arithmetic', () {
       double f1 = 1.0;
       double f2 = 2.0;
       Half  h1 = new Half(3);
       Half  h2 = new Half(4);

       h1 = new Half(f1 + f2);
       expect(h1.toDouble(), equals(3.0));

       h2 += f1;
       expect(h2.toDouble(), equals(5.0));

       h2 = h1 + h2;
       expect(h2.toDouble(), equals(8.0));

       h2 += h1;
       expect(h2.toDouble(), equals(11.0));

       h2 = -h2;
       expect(h2.toDouble(), equals(-11.0));
     });
  });
}
