import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/motion_feedback.dart';
import 'package:inkstamp/features/camera/data/repositories/dev_asset_capture_source.dart';
import 'package:inkstamp/features/camera/presentation/controllers/camera_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({this.initializeCamera = true, super.key});

  final bool initializeCamera;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  late final InkstampCameraController _controller;
  int? _cameraLease;
  double _zoom = 1;
  Timer? _flashTimer;
  Timer? _focusTimer;
  bool _shutterFlash = false;
  Offset? _focusPoint;
  int _focusRevision = 0;
  bool _navigating = false;
  bool _choosingSample = false;
  String? _sampleAsset;
  bool _focusVisible = false;
  bool _showGrid = false;
  double _lensTurns = 0;

  Future<void> _switchLens() async {
    if (ref.read(cameraControllerProvider).phase != CameraPhase.ready) return;
    setState(() => _lensTurns += .5);
    await _controller.switchLens();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(cameraControllerProvider.notifier);
    if (widget.initializeCamera) _cameraLease = _controller.acquireSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.initializeCamera) {
      _controller.onLifecycleChanged(state);
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _focusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.initializeCamera) {
      // Riverpod state must not be changed while the router unmounts widgets.
      _controller.releaseSession(_cameraLease!);
    }
    super.dispose();
  }

  Future<void> _capture(CameraControllerState state) async {
    if (_navigating || _choosingSample || state.phase != CameraPhase.ready) {
      return;
    }
    _navigating = true;
    try {
      final sample = devAssetCaptureEnabled ? _sampleAsset : null;
      await _openCapturedPreview(
        sample == null
            ? await _controller.capture()
            : await _controller.captureDevAsset(sample),
      );
    } finally {
      _navigating = false;
    }
  }

  Future<void> _chooseSample() async {
    if (!devAssetCaptureEnabled || _navigating || _choosingSample) return;
    _choosingSample = true;
    try {
      final images = await ref.read(devAssetCaptureSourceProvider).listImages();
      if (!mounted) return;
      if (images.isEmpty && _sampleAsset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No supported images in assets/image_test/.'),
          ),
        );
        return;
      }
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('DEV sample capture')),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera thật'),
                onTap: () => Navigator.pop(context, ''),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: images.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(images[index].split('/').last),
                    onTap: () => Navigator.pop(context, images[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => _sampleAsset = selected.isEmpty ? null : selected);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load the DEV sample image.')),
        );
      }
    } finally {
      _choosingSample = false;
      _navigating = false;
    }
  }

  Future<void> _openCapturedPreview(bool captured) async {
    if (captured && mounted) {
      await _controller.suspend(waitForPreviewFrame: true);
    }
    if (captured && mounted) {
      await context.push(AppRoutes.cameraPreview);
      if (mounted && widget.initializeCamera) await _controller.initialize();
    }
  }

  Future<void> _focus(TapDownDetails details, Size size) async {
    if (devAssetCaptureEnabled && _sampleAsset != null) return;
    final point = details.localPosition;
    final supported = await _controller.focusAt(
      Offset(
        (point.dx / size.width).clamp(0, 1),
        (point.dy / size.height).clamp(0, 1),
      ),
    );
    if (!supported || !mounted) return;
    _focusTimer?.cancel();
    setState(() {
      _focusPoint = point;
      _focusRevision++;
      _focusVisible = true;
    });
    _focusTimer = Timer(AppMotion.focusHold, () {
      if (mounted) setState(() => _focusVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initializeCamera) {
      ref.listen(cameraControllerProvider, (previous, next) {
        if (previous?.phase == CameraPhase.capturing &&
            next.phase == CameraPhase.processing) {
          _flashTimer?.cancel();
          setState(() => _shutterFlash = true);
          _flashTimer = Timer(AppMotion.shutter, () {
            if (mounted) setState(() => _shutterFlash = false);
          });
        }
      });
    }
    final CameraControllerState state = widget.initializeCamera
        ? ref.watch(cameraControllerProvider)
        : const CameraControllerState(phase: CameraPhase.unavailable);
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedOpacity(
            opacity: state.phase == CameraPhase.initializing ? .75 : 1,
            duration: AppMotion.duration(context, AppMotion.fast),
            child: _CameraFeed(
              state: state,
              zoom: _zoom,
              designPreview: !widget.initializeCamera,
              sampleAsset: devAssetCaptureEnabled ? _sampleAsset : null,
            ),
          ),
          const _CameraShade(),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: widget.initializeCamera
                    ? (details) => _focus(details, constraints.biggest)
                    : null,
              ),
            ),
          ),
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 22,
              top: _focusPoint!.dy - 22,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _focusVisible ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.fast),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_focusRevision),
                    tween: Tween(begin: 1.1, end: 1),
                    duration: AppMotion.duration(context, AppMotion.fast),
                    builder: (_, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _shutterFlash ? .12 : 0,
              duration: AppMotion.duration(context, AppMotion.shutter),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 20,
                  right: 20,
                  top: 4,
                  child: Row(
                    children: <Widget>[
                      const _DarkPill(child: _CameraTitle()),
                      const Spacer(),
                      if (devAssetCaptureEnabled &&
                          widget.initializeCamera) ...[
                        _RoundControl(
                          tooltip: 'DEV sample capture',
                          icon: Icons.image_outlined,
                          onPressed: state.isBusy ? null : _chooseSample,
                          active: _sampleAsset != null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _RoundControl(
                        tooltip: 'Flash',
                        icon: state.flashEnabled
                            ? Icons.flash_on_outlined
                            : Icons.flash_off_outlined,
                        onPressed: state.phase == CameraPhase.ready
                            ? _controller.toggleFlash
                            : null,
                        active: state.flashEnabled,
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        tooltip: 'Switch camera',
                        icon: Icons.flip_camera_ios_outlined,
                        turns: _lensTurns,
                        onPressed: state.phase == CameraPhase.ready
                            ? _switchLens
                            : null,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, 8),
                    child: FractionallySizedBox(
                      widthFactor: 0.81,
                      child: AspectRatio(
                        aspectRatio: 3.2 / 4.2,
                        child: CustomPaint(
                          foregroundPainter: _StampFramePainter(),
                          child: const Padding(
                            padding: EdgeInsets.all(15),
                            child: _StampFrameContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.errorMessage != null)
                  Positioned(
                    top: 90,
                    left: 70,
                    right: 70,
                    child: _CameraError(
                      message: state.errorMessage!,
                      onRetry: _controller.initialize,
                    ),
                  ),
                if (state.isBusy)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 91,
                  child: Center(
                    child: _ZoomSelector(
                      zoom: _zoom,
                      onChanged: (double value) =>
                          setState(() => _zoom = value),
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _RecentStamp(designPreview: !widget.initializeCamera),
                      PressFeedback(
                        enabled: state.phase == CameraPhase.ready,
                        child: _Shutter(
                          busy:
                              state.phase == CameraPhase.capturing ||
                              state.phase == CameraPhase.processing,
                          onTap: state.phase == CameraPhase.ready
                              ? () => _capture(state)
                              : null,
                        ),
                      ),
                      _RoundControl(
                        tooltip: 'Grid',
                        icon: Icons.grid_view_outlined,
                        size: 48,
                        active: _showGrid,
                        onPressed: () => setState(() => _showGrid = !_showGrid),
                      ),
                    ],
                  ),
                ),
                if (_showGrid)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFeed extends StatelessWidget {
  const _CameraFeed({
    required this.state,
    required this.zoom,
    this.designPreview = false,
    this.sampleAsset,
  });
  final CameraControllerState state;
  final double zoom;
  final bool designPreview;
  final String? sampleAsset;

  @override
  Widget build(BuildContext context) {
    final Object? handle = state.previewHandle;
    final Widget feed;
    if (devAssetCaptureEnabled && sampleAsset != null) {
      feed = Image.asset(
        sampleAsset!,
        key: const ValueKey('dev-camera-static-preview'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Không đọc được ảnh. Chọn ảnh khác hoặc Camera thật.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (handle is camera.CameraController &&
        handle.value.isInitialized) {
      final portrait =
          MediaQuery.orientationOf(context) == Orientation.portrait;
      final size = handle.value.previewSize!;
      feed = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: portrait ? size.height : size.width,
          height: portrait ? size.width : size.height,
          child: camera.CameraPreview(handle),
        ),
      );
    } else {
      feed = designPreview
          ? Image.asset(EditorialAssets.camera, fit: BoxFit.cover)
          : const ColoredBox(color: Colors.black);
    }
    return ClipRect(
      child: Transform.scale(
        scale: zoom,
        child: SizedBox.expand(
          child: ColoredBox(color: Colors.black, child: feed),
        ),
      ),
    );
  }
}

class _CameraShade extends StatelessWidget {
  const _CameraShade();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.43),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.59),
          ],
          stops: const <double>[0, 0.46, 1],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CameraTitle extends StatelessWidget {
  const _CameraTitle();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 118,
      height: 48,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'INKSTAMP',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Text('/', style: TextStyle(color: Colors.white38)),
            ),
            Text(
              'máy ảnh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.turns = 0,
    this.active = false,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double turns;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0x66201F1B),
            disabledForegroundColor: Colors.white,
            disabledBackgroundColor: const Color(0x66201F1B),
            side: const BorderSide(color: Color(0x55FFFFFF)),
          ),
          icon: AnimatedRotation(
            turns: turns,
            duration: AppMotion.duration(context, AppMotion.standard),
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.fast),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 21,
                color: active ? const Color(0xFFFFC568) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = .7;
    for (final part in <double>[1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(size.width * part, 0),
        Offset(size.width * part, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * part),
        Offset(size.width, size.height * part),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StampFrameContent extends StatelessWidget {
  const _StampFrameContent();
  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: <Widget>[
        Positioned(
          top: 7,
          left: 7,
          right: 7,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 130,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _ActiveStampBadge(),
                ),
              ),
              Spacer(),
              TechnicalText('CROP 3:4', color: Colors.white70, fontSize: 10),
            ],
          ),
        ),
        Positioned(
          left: 7,
          right: 7,
          bottom: 7,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TechnicalText(
                  'INKSTAMP · VN-026',
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1.7,
                ),
                SizedBox(width: 30),
                TechnicalText(
                  '35MM · N° 0142',
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveStampBadge extends StatelessWidget {
  const _ActiveStampBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA035332D),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFA900),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 6),
            ),
            SizedBox(width: 8),
            TechnicalText(
              'STAMP ACTIVE',
              color: Colors.white,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _StampFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint solid = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      solid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      solid,
    );
    final Paint dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final Path border = Path()
      ..addRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4));
    for (final PathMetric metric in border.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), dash);
        distance += 14;
      }
    }
    final Paint corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    const double inset = 17;
    const double arm = 14;
    final Path marks = Path()
      ..moveTo(inset, inset + arm)
      ..lineTo(inset, inset)
      ..lineTo(inset + arm, inset)
      ..moveTo(size.width - inset - arm, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + arm)
      ..moveTo(inset, size.height - inset - arm)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset + arm, size.height - inset)
      ..moveTo(size.width - inset - arm, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset - arm);
    canvas.drawPath(marks, corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZoomSelector extends StatelessWidget {
  const _ZoomSelector({required this.zoom, required this.onChanged});
  final double zoom;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    const List<(double, String)> values = <(double, String)>[
      (0.92, '28mm'),
      (1, '35mm'),
      (1.12, '50mm'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB026241F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: values.map(((double, String) item) {
            final bool selected = item.$1 == zoom;
            return GestureDetector(
              onTap: () => onChanged(item.$1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white60,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecentStamp extends ConsumerWidget {
  const _RecentStamp({this.designPreview = false});
  final bool designPreview;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!designPreview) {
      final memories = ref.watch(stampTimelineControllerProvider).sent;
      final latest = memories.isEmpty ? null : memories.first;
      return SizedBox(
        width: 45,
        height: 60,
        child: Center(
          child: latest == null
              ? const Icon(
                  Icons.photo_outlined,
                  color: Colors.white54,
                  size: 26,
                )
              : Semantics(
                  label: 'Ký ức mới nhất',
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.stamp(latest.id)),
                    child: SizedBox.square(
                      dimension: 45,
                      child: MemoryPhoto(
                        publicId: latest.cloudinaryThumbnailPublicId,
                        decodeSize: 512,
                      ),
                    ),
                  ),
                ),
        ),
      );
    }
    return Container(
      width: 45,
      height: 60,
      padding: const EdgeInsets.all(3),
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Image.asset(EditorialAssets.camera, fit: BoxFit.cover),
          ),
          const SizedBox(height: 2),
          const Text(
            '#141',
            style: TextStyle(
              color: Color(0xFF1A1C1B),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chụp ảnh',
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD7D7D2)),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Center(
                    child: SizedBox.square(
                      dimension: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFCDCFCD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
