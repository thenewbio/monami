import 'package:monami/src/presentation/views/components/animation/lottie_animation_view.dart';
import 'package:monami/src/presentation/views/components/animation/models/lottie_animation.dart';

class LoadingAnimationView extends LottieAnimationView {
  const LoadingAnimationView({super.key})
      : super(
          animation: LottieAnimation.loading,
        );
}
