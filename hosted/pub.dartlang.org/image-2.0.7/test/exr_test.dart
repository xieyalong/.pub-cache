import 'dart:io' as Io;
import 'package:image/image.dart';

void main() {
  List<int> bytes = new Io.File('test/res/exr/grid.exr').readAsBytesSync();

  ExrDecoder dec = new ExrDecoder();
  dec.startDecode(bytes);
  Image img = dec.decodeFrame(0);

  List<int> png = new PngEncoder().encodeImage(img);
  new Io.File('out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
}
