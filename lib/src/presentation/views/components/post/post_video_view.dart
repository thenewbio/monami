import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:monami/src/data/state/post/models/post.dart';
import 'package:monami/src/presentation/views/components/animation/models/error_animation.dart';
import 'package:monami/src/presentation/views/components/animation/models/loadin_animation.dart';
import 'package:video_player/video_player.dart';

class PostVideoView extends HookWidget {
  final Post post;

  const PostVideoView({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = VideoPlayerController.network(
      post.fileUrl,
    );

    final isVideoPlayerReady = useState(false);

    useEffect(() {
      controller.initialize().then(
        (value) {
          isVideoPlayerReady.value = true;
          controller.setLooping(true);
          controller.play();
        },
      );
      return controller.dispose;
    }, [controller]);

    switch (isVideoPlayerReady.value) {
      case true:
        return AspectRatio(
          aspectRatio: post.aspectRatio,
          child: VideoPlayer(controller),
        );
      case false:
        return const LoadingAnimationView();
      default:
        return const ErrorAnimationView();
    }
  }
}
