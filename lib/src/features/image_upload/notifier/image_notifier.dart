import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:monami/src/data/state/constants/firebase_collection.dart';
import 'package:monami/src/features/image_upload/constants/constants.dart';
import 'package:monami/src/features/image_upload/exception/could_not_build_thumbnail.dart';
import 'package:monami/src/features/image_upload/extension/get_collectionname_from_file_type.dart';
import 'package:monami/src/features/image_upload/extension/get_image_data_aspect_ratio.dart';
import 'package:monami/src/features/image_upload/models/file_type.dart';
import 'package:monami/src/features/image_upload/typedef/is_loading.dart';
// import 'package:monami/state/post/models/post_key.dart';
import 'package:monami/src/data/state/post/models/post_payload.dart';
import 'package:monami/src/data/state/post_settings/models/post_settings.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ImageUploadNotifier extends StateNotifier<IsLoading> {
  ImageUploadNotifier() : super(false);

  set isLoading(bool value) => state = value;

  Future<bool> upload({
    required File file,
    required FileType fileType,
    required String message,
    required Map<PostSetting, bool> postSettings,
    required String userId,
    required String category,
  }) async {
    isLoading = true;

    late Uint8List thumbnailUint8List;

    switch (fileType) {
      case FileType.image:
        // create a thumbnail out of the file
        final fileAsImage = img.decodeImage(file.readAsBytesSync());
        if (fileAsImage == null) {
          isLoading = false;
          throw const CouldNotBuildThumbnailException();
        }
        // create thumbnail
        final thumbnail = img.copyResize(
          fileAsImage,
          width: Constants.imageThumbnailWidth,
        );
        final thumbnailData = img.encodeJpg(thumbnail);
        thumbnailUint8List = Uint8List.fromList(thumbnailData);
        break;
      case FileType.video:
        final thumb = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: Constants.videoThumbnailMaxHeight,
          quality: Constants.videoThumbnailQuality,
        );
        if (thumb == null) {
          isLoading = false;
          throw const CouldNotBuildThumbnailException();
        } else {
          thumbnailUint8List = thumb;
        }
        break;
    }

    // calculate the aspect ratio

    final thumbnailAspectRatio = await thumbnailUint8List.getAspectRatio();

    // calculate references

    final fileName = const Uuid().v4();

    // create references to the thumbnail and the image itself

    final thumbnailRef = FirebaseStorage.instance
        .ref()
        .child(userId)
        .child(FirebaseCollectionName.thumbnail)
        .child(fileName);

    final originalFileRef = FirebaseStorage.instance
        .ref()
        .child(userId)
        .child(fileType.collectionName)
        .child(fileName);

    try {
      // upload the thumbnail
      final thumbnailUploadTask =
          await thumbnailRef.putData(thumbnailUint8List);
      final thumbnailStorageId = thumbnailUploadTask.ref.name;

      // upload the original image
      final originalFileUploadTask = await originalFileRef.putFile(file);
      final originalFileStorageId = originalFileUploadTask.ref.name;

      // upload the post itself
      final postPayload = PostPayLoad(
        userId: userId,
        message: message,
        thumbnailUrl: await thumbnailRef.getDownloadURL(),
        fileUrl: await originalFileRef.getDownloadURL(),
        fileType: fileType,
        fileName: fileName,
        aspectRatio: thumbnailAspectRatio,
        postSettings: postSettings,
        thumbnailStorageId: thumbnailStorageId,
        originalFileStorageId: originalFileStorageId,
        postStatus: "Not Approved",
        category: category,
      );
      await FirebaseFirestore.instance
          .collection(FirebaseCollectionName.products)
          .add(postPayload);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }
}
