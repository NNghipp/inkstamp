import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkstamp/app/theme/app_colors.dart';
import 'package:inkstamp/app/theme/app_spacing.dart';
import 'package:inkstamp/core/widgets/inkstamp_scaffold.dart';
import 'package:inkstamp/features/friends/domain/entities/friend.dart';
import 'package:inkstamp/features/friends/presentation/controllers/friends_controller.dart';
import 'package:inkstamp/features/friends/presentation/widgets/friend_tile.dart';

class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({this.initialUsername, super.key});

  final String? initialUsername;

  @override
  ConsumerState<FriendSearchScreen> createState() {
    return _FriendSearchScreenState();
  }
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  Timer? _debounce;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername ?? '');
    if (_controller.text.isNotEmpty) {
      Future<void>.microtask(
        () => ref
            .read(friendsControllerProvider.notifier)
            .search(_controller.text),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FriendsState state = ref.watch(friendsControllerProvider);

    return InkstampScaffold(
      title: 'Find friends',
      body: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            onChanged: _onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Search by username',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          if (state.isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: state.searchResults.isEmpty
                  ? const Center(
                      child: Text('Enter a username to find someone.'),
                    )
                  : ListView.separated(
                      itemCount: state.searchResults.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: AppSpacing.sm);
                      },
                      itemBuilder: (context, index) {
                        final InkstampFriend friend =
                            state.searchResults[index];
                        return FriendTile(
                          friend: friend,
                          trailing: _trailing(context, state, friend),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _trailing(
    BuildContext context,
    FriendsState state,
    InkstampFriend friend,
  ) {
    if (friend.status == FriendStatus.accepted) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success);
    }
    if (friend.status == FriendStatus.pending) {
      return const Chip(label: Text('Pending'));
    }
    if (friend.status == FriendStatus.blocked) {
      return const Chip(label: Text('Blocked'));
    }
    final bool busy = state.busyUserIds.contains(friend.id);
    return FilledButton(
      onPressed: busy
          ? null
          : () async {
              final bool sent = await ref
                  .read(friendsControllerProvider.notifier)
                  .sendRequest(friend);
              if (sent && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Friend request sent to ${friend.displayName}.',
                    ),
                  ),
                );
              }
            },
      child: Text(busy ? 'Sending…' : 'Add'),
    );
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(friendsControllerProvider.notifier).search(query);
    });
  }
}
