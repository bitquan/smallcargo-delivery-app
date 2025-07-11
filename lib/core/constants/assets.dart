class Assets {
  // Base paths
  static const String _imagesPath = 'assets/images/';
  static const String _iconsPath = 'assets/icons/';
  
  // Logo and branding
  static const String logo = '${_imagesPath}logo.png';
  static const String logoSmall = '${_imagesPath}logo_small.png';
  
  // Icons
  static const String cargoIcon = '${_iconsPath}cargo.png';
  static const String truckIcon = '${_iconsPath}truck.png';
  static const String mapIcon = '${_iconsPath}map.png';
  static const String profileIcon = '${_iconsPath}profile.png';
  
  // Images
  static const String noImage = '${_imagesPath}no_image.png';
  static const String emptyState = '${_imagesPath}empty_state.png';
  static const String splashBackground = '${_imagesPath}splash_bg.png';
  
  // Animations/Lottie files (if needed)
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  
  // Check if asset exists
  static bool isValidAsset(String path) {
    return path.isNotEmpty;
  }
}
