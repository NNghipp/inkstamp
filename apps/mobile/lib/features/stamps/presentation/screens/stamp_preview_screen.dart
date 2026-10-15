import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_motion.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';
import 'package:inkstamp/core/images/stamp_image_format.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/motion_feedback.dart';
import 'package:inkstamp/core/widgets/stamp_date_overlay.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/stamps/domain/entities/stamp.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/post_capture_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_composer_controller.dart';
import 'package:inkstamp/features/stamps/presentation/controllers/stamp_timeline_controller.dart';
import 'package:intl/intl.dart';

class StampPreviewScreen extends ConsumerStatefulWidget {
  const StampPreviewScreen({this.designPreview = false, super.key});
  final bool designPreview;

  @override
  ConsumerState<StampPreviewScreen> createState() => _StampPreviewScreenState();
}

class _StampPreviewScreenState extends ConsumerState<StampPreviewScreen> {
  bool _leaving = false;

  Future<void> _returnToCamera() async {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.camera);
    }
  }

  Future<void> _discard() async {
    if (_leaving) return;
    final controller = ref.read(postCaptureControllerProvider.notifier);
    if (controller.busy) return;
    setState(() => _leaving = true);
    final discard = controller.discard();
    await Future<void>.delayed(AppMotion.duration(context, AppMotion.standard));
    if (await discard) await _returnToCamera();
  }

  Future<void> _send() async {
    final controller = ref.read(postCaptureControllerProvider.notifier);
    if (!await controller.send() || !mounted) return;
    await Future<void>.delayed(AppMotion.duration(context, AppMotion.success));
    if (!mounted) return;
    await controller.finish();
    await _returnToCamera();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(stampComposerControllerProvider);
    final phase = ref.watch(postCaptureControllerProvider);
    final friendsState = widget.designPreview
        ? const FriendsState()
        : ref.watch(friendsControllerProvider);
    final friends = friendsState.friends
        .where((f) => f.status == FriendStatus.accepted)
        .toList();
    final busy =
        phase == PostCapturePhase.sending ||
        phase == PostCapturePhase.sent ||
        _leaving;
    final locked =
        !widget.designPreview &&
        ref
            .watch(stampTimelineControllerProvider.notifier)
            .isRetryLocked(draft);
    final valid =
        draft.localImagePath != null &&
        !friendsState.isLoading &&
        (locked ||
            (draft.audience == AudienceMode.selected
                ? draft.selectedRecipientIds.any(
                    (id) => friends.any((f) => f.id == id),
                  )
                : friends.isNotEmpty || draft.replyToStampId != null));
    return PopScope(
      canPop: widget.designPreview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _discard();
      },
      child: Scaffold(
        backgroundColor: EditorialColors.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 12, 26, 24),
            children: <Widget>[
              SizedBox(
                height: 49,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Hủy ảnh',
                        onPressed: busy ? null : _discard,
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: GalleryTokens.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: GalleryTokens.line),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TechnicalText('INKSTAMP', fontSize: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 7),
                              child: Text(
                                '/',
                                style: TextStyle(
                                  color: Color(0xFFABABA5),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              'chi tiết ký ức',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: widget.designPreview
                          ? const EditorialAvatar(size: 29)
                          : UserAvatar(
                              name:
                                  ref
                                      .watch(sessionControllerProvider)
                                      .user
                                      ?.displayName ??
                                  'InkStamp',
                              size: 29,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SettleIn(
                child: AnimatedOpacity(
                  opacity: _leaving ? 0 : 1,
                  duration: AppMotion.duration(context, AppMotion.standard),
                  child: AnimatedScale(
                    scale: _leaving ? .98 : 1,
                    duration: AppMotion.duration(context, AppMotion.standard),
                    child: _PreviewStamp(
                      localImagePath: widget.designPreview
                          ? null
                          : draft.localImagePath,
                      capturedAt: draft.captureTime,
                      designPreview: widget.designPreview,
                      phase: phase,
                      onReject: busy ? null : _discard,
                      onAccept: !busy && valid ? _send : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (draft.title != null)
                Text(draft.title!, textAlign: TextAlign.center),
              if (draft.locationLabel != null)
                Text(
                  draft.locationLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EditorialColors.muted,
                    fontSize: 12,
                  ),
                ),
              if (widget.designPreview)
                _StampFacts(
                  stampShaped: isProcessedStampImage(draft.localImagePath),
                ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  const TechnicalText(
                    'GỬI ĐẾN',
                    color: EditorialColors.ink,
                    fontSize: 10,
                  ),
                  const Spacer(),
                  Text(
                    widget.designPreview
                        ? 'Tất cả bạn thân (4)'
                        : draft.audience == AudienceMode.allFriends
                        ? 'Tất cả bạn bè (${friends.length})'
                        : '${draft.selectedRecipientIds.length} người nhận',
                    style: const TextStyle(
                      color: EditorialColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: widget.designPreview
                      ? MediaQuery.sizeOf(context).width - 52
                      : null,
                  child: Row(
                    mainAxisAlignment: widget.designPreview
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                    children: <Widget>[
                      _Recipient(
                        label: 'Tất cả',
                        selected: draft.audience == AudienceMode.allFriends,
                        icon: Icons.groups_outlined,
                        onTap: busy || locked
                            ? null
                            : () => ref
                                  .read(
                                    stampComposerControllerProvider.notifier,
                                  )
                                  .setAudience(AudienceMode.allFriends),
                      ),
                      if (widget.designPreview) ...<Widget>[
                        const _Recipient(
                          label: 'Lan',
                          image: EditorialAssets.preview,
                          selected: false,
                          onTap: null,
                        ),
                        const _Recipient(
                          label: 'Minh',
                          image: EditorialAssets.portrait,
                          selected: false,
                          grayscale: true,
                          onTap: null,
                        ),
                        const _Recipient(
                          label: 'An',
                          image: EditorialAssets.preview,
                          selected: false,
                          onTap: null,
                        ),
                        const _Recipient(
                          label: 'Vy',
                          image: EditorialAssets.portrait,
                          selected: false,
                          onTap: null,
                        ),
                      ] else
                        for (final friend in friends) ...<Widget>[
                          const SizedBox(width: 20),
                          _Recipient(
                            label: friend.displayName,
                            selected:
                                draft.audience == AudienceMode.selected &&
                                draft.selectedRecipientIds.contains(friend.id),
                            onTap: busy || locked
                                ? null
                                : () => ref
                                      .read(
                                        stampComposerControllerProvider
                                            .notifier,
                                      )
                                      .toggleRecipient(friend.id),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              if (!widget.designPreview && phase == PostCapturePhase.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Không thể gửi ảnh.',
                          semanticsLabel:
                              'Không thể gửi ảnh. Ảnh được giữ lại để thử lại.',
                        ),
                      ),
                      TextButton(
                        onPressed: valid ? _send : null,
                        child: const Text('Thử lại'),
                      ),
                      TextButton(onPressed: _discard, child: const Text('Hủy')),
                    ],
                  ),
                ),
              if (!widget.designPreview && phase == PostCapturePhase.sent)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Đã gửi', textAlign: TextAlign.center),
                ),
              if (!widget.designPreview && friendsState.errorMessage != null)
                TextButton(
                  onPressed: busy
                      ? null
                      : () =>
                            ref.read(friendsControllerProvider.notifier).load(),
                  child: const Text('Không thể tải bạn bè. Thử lại'),
                ),
              if (!widget.designPreview &&
                  friends.isEmpty &&
                  !friendsState.isLoading)
                const Text(
                  'Thêm bạn bè để gửi khoảnh khắc.',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 22),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TechnicalText('CHẠM', fontSize: 8, color: Color(0xFF9A9A94)),
                  SizedBox(width: 6),
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: GalleryTokens.surface,
                    child: Icon(Icons.check, color: Colors.white, size: 8),
                  ),
                  SizedBox(width: 6),
                  TechnicalText(
                    'ĐỂ GỬI NGAY LẬP TỨC',
                    fontSize: 8,
                    color: Color(0xFF9A9A94),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStamp extends StatelessWidget {
  const _PreviewStamp({
    required this.onReject,
    required this.onAccept,
    this.localImagePath,
    this.designPreview = false,
    this.phase = PostCapturePhase.idle,
    this.capturedAt,
  });
  final VoidCallback? onReject;
  final VoidCallback? onAccept;
  final String? localImagePath;
  final bool designPreview;
  final PostCapturePhase phase;
  final DateTime? capturedAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: isProcessedStampImage(localImagePath) ? 1 : 0.76,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (localImagePath != null)
                      StampDateOverlay(
                        date: capturedAt ?? DateTime.now(),
                        bottom: 48,
                        child: Image.file(
                          File(localImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Text('Không thể đọc ảnh.')),
                        ),
                      )
                    else if (designPreview)
                      Image.asset(EditorialAssets.preview, fit: BoxFit.cover)
                    else
                      const ColoredBox(
                        color: GalleryTokens.surface,
                        child: Center(child: Text('Chụp ảnh để tạo tem.')),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xB8302E28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Row(
                            children: <Widget>[
                              const CircleAvatar(
                                radius: 3,
                                backgroundColor: GalleryTokens.accent,
                              ),
                              const SizedBox(width: 6),
                              TechnicalText(
                                designPreview
                                    ? 'PARIS · 15:42'
                                    : DateFormat(
                                        'HH:mm',
                                      ).format(capturedAt ?? DateTime.now()),
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _DecisionButton(
                        icon: Icons.close,
                        onTap: onReject,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _DecisionButton(
                        icon: Icons.check,
                        onTap: onAccept,
                        outlined: true,
                        busy: phase == PostCapturePhase.sending,
                        success: phase == PostCapturePhase.sent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              if (designPreview)
                Row(
                  children: <Widget>[
                    const TechnicalText(
                      'INKSTAMP · VIETNAM',
                      color: EditorialColors.ink,
                      fontSize: 7,
                    ),
                    const Spacer(),
                    TechnicalText(
                      designPreview
                          ? 'TEM #142 · HN-026 · 26.09.2026'
                          : DateFormat(
                              'dd.MM.yyyy',
                            ).format(capturedAt ?? DateTime.now()),
                      color: EditorialColors.ink,
                      fontSize: 7,
                    ),
                  ],
                ),
              const SizedBox(height: 3),
              if (designPreview)
                Row(
                  children: <Widget>[
                    const TechnicalText(
                      'KHOẢNH KHẮC THẬT · KHÔNG QUA CHỈNH SỬA',
                      fontSize: 6,
                      letterSpacing: 0.45,
                    ),
                    const Spacer(),
                    TechnicalText(
                      designPreview ? '35MM · F/2.0 ·\n1/500S' : 'ẢNH ĐÃ XỬ LÝ',
                      fontSize: 6,
                      letterSpacing: 0.35,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.busy = false,
    this.success = false,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool busy;
  final bool success;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: icon == Icons.close
          ? 'Hủy ảnh'
          : busy
          ? 'Đang gửi'
          : success
          ? 'Đã gửi'
          : 'Gửi ảnh',
      child: PressFeedback(
        enabled: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xCC262622),
              borderRadius: BorderRadius.circular(10),
              border: outlined ? Border.all(color: Colors.white60) : null,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.fast),
              child: busy
                  ? const SizedBox(
                      key: ValueKey('sending'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      icon,
                      key: ValueKey(success),
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampFacts extends StatelessWidget {
  const _StampFacts({this.stampShaped = false});
  final bool stampShaped;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const TechnicalText(
          'ĐÃ ĐÓNG DẤU KỸ THUẬT\nSỐ',
          color: EditorialColors.ink,
          fontSize: 8,
        ),
        const TechnicalText('·', fontSize: 10),
        TechnicalText(stampShaped ? 'CROP\n1:1' : 'CROP\n3:4', fontSize: 8),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lock_outline, size: 13, color: EditorialColors.muted),
            SizedBox(width: 5),
            Text(
              'Chỉ người nhận xem\nđược',
              style: TextStyle(
                fontSize: 10,
                color: EditorialColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Recipient extends StatelessWidget {
  const _Recipient({
    required this.label,
    required this.selected,
    required this.onTap,
    this.image,
    this.icon,
    this.grayscale = false,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? image;
  final IconData? icon;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: PressFeedback(
        enabled: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: SelectionFeedback(
            selected: selected,
            child: SizedBox(
              width: 51,
              child: Column(
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: AppMotion.duration(context, AppMotion.fast),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: GalleryTokens.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(
                                  color: EditorialColors.ink,
                                  width: 1.5,
                                )
                              : null,
                          image: image == null
                              ? null
                              : DecorationImage(
                                  image: AssetImage(image!),
                                  fit: BoxFit.cover,
                                  colorFilter: grayscale
                                      ? const ColorFilter.mode(
                                          Colors.grey,
                                          BlendMode.saturation,
                                        )
                                      : null,
                                ),
                        ),
                        child: icon != null
                            ? Icon(icon, size: 23)
                            : image != null
                            ? null
                            : Center(
                                child: Text(
                                  label.characters.firstOrNull ?? '?',
                                ),
                              ),
                      ),
                      if (selected)
                        const Positioned(
                          right: -4,
                          bottom: -4,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: GalleryTokens.surface,
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
