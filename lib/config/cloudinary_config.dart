// lib/config/cloudinary_config.dart
class CloudinaryConfig {
  // Ganti dengan credentials Cloudinary Anda
  static const String cloudName = "djl2sukor";
  static const String uploadPreset = "service_reports"; // Buat di Cloudinary
  static const String apiKey = "379534721643839";
  
  // Base URL untuk upload
  static String get uploadUrl => "https://api.cloudinary.com/v1_1/$cloudName/auto/upload";
  
  // Base URL untuk menampilkan gambar (public ID)
  static String getImageUrl(String publicId) {
    return "https://res.cloudinary.com/$cloudName/image/upload/$publicId";
  }
  
  // Base URL untuk video
  static String getVideoUrl(String publicId) {
    return "https://res.cloudinary.com/$cloudName/video/upload/$publicId";
  }
}