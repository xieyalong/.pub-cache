import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('PNG', () {
    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PNG
      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/png/encode.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
    });

    test('encodeAnimation', () {
      Animation anim = new Animation();
      anim.loopCount = 10;
      for (var i = 0; i < 10; i++) {
        Image image = new Image(480, 120);
        drawString(image, arial_48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      List<int> png = encodePngAnimation(anim);
      new Io.File('out/png/encodeAnimation.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });

    test('decode', () {
      List<int> bytes = new Io.File('out/png/encode.png').readAsBytesSync();
      Image image = new PngDecoder().decodeImage(bytes);

      expect(image.width, equals(64));
      expect(image.height, equals(64));
      var c = getColor(100, 200, 255);
      for (int i = 0, len = image.length; i < len; ++i) {
        expect(image[i], equals(c));
      }

      List<int> png = new PngEncoder().encodeImage(image);
      new Io.File('out/png/decode.png')
            .writeAsBytesSync(png);
    });

    test('iCCP', () {
      final bytes = new Io.File('test/res/png/iCCP.png').readAsBytesSync();
      final image = new PngDecoder().decodeImage(bytes);
      expect(image.iccProfile, isNotNull);
      expect(image.iccProfile.data, isNotNull);

      final png = new PngEncoder().encodeImage(image);

      final image2 = new PngDecoder().decodeImage(png);
      expect(image2.iccProfile, isNotNull);
      expect(image2.iccProfile.data, isNotNull);
      expect(image2.iccProfile.data.length, equals(image.iccProfile.data.length));
    });


    Io.Directory dir = new Io.Directory('test/res/png');
    List files = dir.listSync();

    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.png')) {
        continue;
      }

      // PngSuite File naming convention:
      // filename:                                g04i2c08.png
      //                                          || ||||
      //  test feature (in this case gamma) ------+| ||||
      //  parameter of test (here gamma-value) ----+ ||||
      //  interlaced or non-interlaced --------------+|||
      //  color-type (numerical) ---------------------+||
      //  color-type (descriptive) --------------------+|
      //  bit-depth ------------------------------------+
      //
      //  color-type:
      //
      //    0g - grayscale
      //    2c - rgb color
      //    3p - paletted
      //    4a - grayscale + alpha channel
      //    6a - rgb color + alpha channel
      //    bit-depth:
      //      01 - with color-type 0, 3
      //      02 - with color-type 0, 3
      //      04 - with color-type 0, 3
      //      08 - with color-type 0, 2, 3, 4, 6
      //      16 - with color-type 0, 2, 4, 6
      //      interlacing:
      //        n - non-interlaced
      //        i - interlaced
      String name = f.path.split(new RegExp(r'(/|\\)')).last;

      test('PNG $name', () {
        Io.File file = f;

        // x* png's are corrupted and are supposed to crash.
        if (name.startsWith('x')) {
          try {
            new PngDecoder().decodeImage(file.readAsBytesSync());
            throw new ImageException('This image should not have loaded: $name.');
          } catch (e) {
          }
        } else {
          Animation anim = decodeAnimation(file.readAsBytesSync());
          if (anim.length == 1) {
            List<int> png = new PngEncoder().encodeImage(anim[0]);
            new Io.File('out/png/${name}')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(png);
          } else {
            for (int i = 0; i < anim.length; ++i) {
              List<int> png = new PngEncoder().encodeImage(anim[i]);
              new Io.File('out/png/${name}-$i.png')
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(png);
            }
          }
        }
      });
    }
  });
}
