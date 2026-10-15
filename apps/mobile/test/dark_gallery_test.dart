import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/spatial_stamp_gallery.dart';
import 'package:inkstamp/core/widgets/stamp_artwork.dart';
import 'package:inkstamp/features/camera/data/stamp_alpha_mask.dart';
import 'package:inkstamp/features/stamps/data/repositories/cloudinary_delivery_repository.dart';

void main() {
  test('dark palette keeps body and overlay text readable', () {
    final theme = AppTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, GalleryTokens.canvas);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'BeVietnamPro');
    double contrast(Color text, Color background) =>
        (text.computeLuminance() + .05) / (background.computeLuminance() + .05);
    expect(contrast(GalleryTokens.text, GalleryTokens.canvas), greaterThan(7));
    expect(
      contrast(GalleryTokens.secondaryText, GalleryTokens.canvas),
      greaterThan(4.5),
    );
    // Worst case: the translucent tag is over an all-white photo.
    final tag = Color.alphaBlend(GalleryTokens.overlay, Colors.white);
    expect(contrast(Colors.white, tag), greaterThan(4.5));
  });

  test('placement is ID-stable, bounded and varied for a large collection', () {
    final rotations = <double>{};
    final scales = <double>{};
    for (var i = 0; i < 1000; i++) {
      final first = StampPlacement.forId('memory-$i');
      StampPlacement.forId('unrelated');
      final again = StampPlacement.forId('memory-$i');
      expect(again.rotation, first.rotation);
      expect(again.scale, first.scale);
      expect(again.offset, first.offset);
      expect(first.rotation.abs(), lessThanOrEqualTo(8 * math.pi / 180));
      expect(first.scale, inInclusiveRange(.88, 1.12));
      expect(first.offset.dx.abs(), lessThanOrEqualTo(.025));
      rotations.add(first.rotation);
      scales.add(first.scale);
    }
    expect(rotations.length, greaterThan(100));
    expect(scales.length, greaterThan(100));
  });

  Widget gallery(List<String> ids, {double textScale = 1}) => MaterialApp(
    theme: AppTheme.dark,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverStampGallery(
              ids: ids,
              itemBuilder: (_, index) => Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: Colors.grey,
                      key: ValueKey('photo-${ids[index]}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Một ký ức được giữ lại',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('gallery positions stay identical across rebuilds', (
    tester,
  ) async {
    final ids = List.generate(6, (i) => 'stable-$i');
    await tester.pumpWidget(gallery(ids));
    final before = [
      for (var i = 0; i < 4; i++)
        tester.getRect(find.byKey(ValueKey('photo-stable-$i'))),
    ];
    await tester.pumpWidget(gallery(List.of(ids)));
    for (var i = 0; i < 4; i++) {
      expect(
        tester.getRect(find.byKey(ValueKey('photo-stable-$i'))),
        before[i],
      );
    }
    expect(before[0].top, isNot(before[1].top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery stays lazy with 1000 stamps and scrolls to later rows', (
    tester,
  ) async {
    final ids = List.generate(1000, (i) => 'lazy-$i');
    await tester.pumpWidget(gallery(ids));
    expect(find.byType(RepaintBoundary).evaluate().length, lessThan(40));
    expect(find.byKey(const ValueKey('photo-lazy-999')), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-lazy-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small gallery with large text has separate rotated hit bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      gallery(List.generate(6, (i) => 'bounds-$i'), textScale: 2),
    );
    final rects = [
      for (var i = 0; i < 6; i++)
        tester.getRect(find.byKey(ValueKey('gallery-bounds-$i'))),
    ];
    for (var i = 0; i < rects.length; i++) {
      expect(rects[i].left, greaterThanOrEqualTo(0));
      expect(rects[i].right, lessThanOrEqualTo(320));
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes detail fade and scale transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(
                AppMotion.duration(context, AppMotion.screen),
                Duration.zero,
              );
              return AppMotion.transition(
                context,
                const AlwaysStoppedAnimation(.5),
                const Text('Detail'),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Detail'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Detail'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'real masked PNG corners reveal dark canvas while photo stays opaque',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'inkstamp-dark-alpha-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = img.Image(width: 120, height: 120, numChannels: 4);
      img.fill(source, color: img.ColorRgba8(200, 90, 50, 255));
      final path = '${directory.path}/photo_stamp_v1.png';
      File(path).writeAsBytesSync(img.encodePng(StampAlphaMask.apply(source)));
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Center(
              child: RepaintBoundary(key: boundary, child: const SizedBox()),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          FileImage(File(path)),
          tester.element(find.byType(Center).first),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Center(
              child: RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                  color: GalleryTokens.canvas,
                  child: SizedBox.square(
                    dimension: 120,
                    child: StampArtwork(seed: 1, localImagePath: path),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ClipPath), findsNothing);
      final rendered = (await tester.runAsync(
        () =>
            (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(),
      ))!;
      final data = (await tester.runAsync(
        () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      List<int> pixel(int x, int y) =>
          List.generate(4, (c) => data.getUint8((y * 120 + x) * 4 + c));
      expect(pixel(0, 0), [21, 22, 25, 255]);
      expect(pixel(60, 60), [200, 90, 50, 255]);
      rendered.dispose();
    },
  );

  testWidgets('old square artwork keeps its legacy renderer on dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Center(
            child: SizedBox.square(
              dimension: 180,
              child: StampArtwork(seed: 7),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ClipPath), findsOneWidget);
    expect(find.byType(StampArtwork), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protected thumbnails preserve the revocable network cache key', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaDeliveryUrlProvider(
            'thumb',
          ).overrideWith((ref) async => 'https://example.test/thumb.png'),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MemoryPhoto(publicId: 'thumb', decodeSize: 512),
        ),
      ),
    );
    await tester.pump();
    expect(tester.widget<Image>(find.byType(Image)).image, isA<NetworkImage>());
  });

  testWidgets('gallery thumbnail assets request only a 512 decode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SizedBox.square(
            dimension: 100,
            child: MemoryPhoto(asset: 'assets/design/tea.jpg', decodeSize: 512),
          ),
        ),
      ),
    );
    final provider =
        tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(provider.width, 512);
  });
}
