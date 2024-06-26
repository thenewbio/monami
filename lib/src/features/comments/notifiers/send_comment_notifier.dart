import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:monami/src/features/comments/models/comment_payload.dart';

import 'package:monami/src/data/state/constants/firebase_collection.dart';
import 'package:monami/src/features/image_upload/typedef/is_loading.dart';
import 'package:monami/src/data/state/post/typedefs/post_id.dart';
import 'package:monami/src/data/state/post/typedefs/user_id.dart';

class SendCommentNotifier extends StateNotifier<IsLoading> {
  SendCommentNotifier() : super(false);

  set isLoading(bool value) => state = value;

  Future<bool> sendComment({
    required UserId fromUserId,
    required PostId onPostId,
    required String review,
  }) async {
    isLoading = true;

    final payload = CommentPayload(
      fromUserId: fromUserId,
      onPostId: onPostId,
      review: review,
    );

    try {
      await FirebaseFirestore.instance
          .collection(
            FirebaseCollectionName.reviews,
          )
          .add(payload);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }
}
