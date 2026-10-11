import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/core/widgets/editorial_ui.dart';
import 'package:inkstamp/core/widgets/memory_photo.dart';
import 'package:inkstamp/core/widgets/motion_feedback.dart';
import 'package:inkstamp/core/widgets/user_avatar.dart';
import 'package:inkstamp/features/inbox/presentation/controllers/inbox_controller.dart';
import 'package:intl/intl.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) ref.read(inboxControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxControllerProvider);
    final controller = ref.read(inboxControllerProvider.notifier);
    return ColoredBox(
      color: EditorialColors.canvas,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              EditorialHeader(
                title: 'hộp thư',
                trailing: IconButton(
                  tooltip: 'Làm mới hộp thư',
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh, size: 22),
                ),
              ),
              if (state.loading) const LinearProgressIndicator(minHeight: 2),
              if (state.error != null)
                TextButton(
                  onPressed: controller.refresh,
                  child: Text('${state.error} Thử lại'),
                ),
              if (!state.loading && state.error == null && state.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'Chưa có stamp mới.\nKhoảnh khắc bạn bè gửi sẽ xuất hiện ở đây.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final stamp in state.items)
                Semantics(
                  button: true,
                  label:
                      '${stamp.senderName}, ${stamp.isSeen ? "Đã đọc" : "Chưa đọc"}, '
                      '${DateFormat('HH:mm · dd/MM').format(stamp.createdAt.toLocal())}',
                  child: PressFeedback(
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.stamp(stamp.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            UserAvatar(name: stamp.senderName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stamp.senderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: stamp.isSeen
                                          ? FontWeight.w400
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'HH:mm · dd/MM',
                                    ).format(stamp.createdAt.toLocal()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: EditorialColors.muted,
                                    ),
                                  ),
                                  if (stamp.shortTitle.isNotEmpty)
                                    Text(
                                      stamp.shortTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (!stamp.isSeen)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  '•',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            Semantics(
                              label: 'Ảnh stamp của ${stamp.senderName}',
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: MemoryPhoto(
                                  publicId: stamp.cloudinaryThumbnailPublicId,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (state.next != null)
                TextButton(
                  onPressed: state.loading ? null : controller.loadMore,
                  child: const Text('Tải thêm'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
