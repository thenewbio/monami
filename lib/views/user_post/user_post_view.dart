import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:monami/state/post/providers/user_post_provider.dart';
import 'package:monami/views/components/animation/models/empty_animation_and_text.dart';
import 'package:monami/views/components/animation/models/error_animation.dart';
import 'package:monami/views/components/animation/models/loadin_animation.dart';
import 'package:monami/views/constants/strings.dart';
import 'package:monami/views/post/post_view.dart';

class UserPostView extends ConsumerWidget {
  const UserPostView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostProvider);
    return RefreshIndicator(
        child: posts.when(data: (posts) {
          if (posts.isEmpty) {
            return const EmptyContentAnimationWihText(
                text: Strings.youHaveNoPosts);
          } else {
            return PostGridView(posts:posts);
          }
        }, error: (error, stackTrace) {
          return const ErrorAnimationView();
        }, loading: () {
          return const LoadingAnimationView();
        }),
        onRefresh: () {
          ref.invalidate(userPostProvider);
          return Future.delayed(const Duration(seconds: 1));
        });
  }
}
