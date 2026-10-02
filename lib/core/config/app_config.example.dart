/// Template for `lib/core/config/app_config.dart`, which is gitignored.
///
/// Copy this file to `app_config.dart` and fill in the two Cloudinary values
/// from your dashboard — see `docs/02-cloudinary-setup.md`.
///
/// Neither value is a secret: the cloud name is part of every delivery URL, and
/// an unsigned upload preset only permits adding a file to the folder you
/// configured. The API *secret* is never used by this app and must never be
/// placed here.
class AppConfig {
  const AppConfig._();

  /// From the Cloudinary dashboard, "Cloud name".
  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  /// The name of your **unsigned** upload preset.
  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  static bool get isCloudinaryConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
