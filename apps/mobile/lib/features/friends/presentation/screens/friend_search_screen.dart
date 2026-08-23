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
  const FriendSearchScreen({super.key});

  @override
  ConsumerState<FriendSearchScreen> createState() {
    return _FriendSearchScreenState();
  }
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
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
            autofocus: true,
            autocorrect: false,
            onChanged: _onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Search by username',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.isLoading)
            const LinearProgressIndicator(color: AppColors.ink)
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
                          trailing: friend.status == FriendStatus.accepted
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                )
                              : FilledButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Friend request sent to ${friend.displayName}.',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Add'),
                                ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(friendsControllerProvider.notifier).search(query);
    });
  }
}
