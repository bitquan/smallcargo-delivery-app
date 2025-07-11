class AppConfig {
  // Google Maps API Configuration
  static const String googleMapsApiKey = 'AIzaSyBirnBdv4bAiKjJCu1i_uKam7VmWFzD90o';
  static const String googlePlacesApiKey = 'AIzaSyBirnBdv4bAiKjJCu1i_uKam7VmWFzD90o';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'small-cargo-t';
  static const String firebaseApiKey = 'AIzaSyAXrXpxeVG2tUBhgp-1bTr3dOVsHRD7Awk';
  
  // App Configuration
  static const String appName = 'Small Cargo';
  static const String appVersion = '1.0.0';
  
  // Default location (NYC)
  static const double defaultLatitude = 40.7128;
  static const double defaultLongitude = -74.0060;
  static const double searchRadiusKm = 50.0;
  
  // Map Configuration
  static const double defaultZoom = 12.0;
  static const int maxSearchResults = 10;
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const String baseUrl = 'https://maps.googleapis.com/maps/api';
  
  // Validation
  static bool get hasValidGoogleApiKey => 
    googleMapsApiKey.isNotEmpty && 
    !googleMapsApiKey.contains('YOUR_API_KEY');
    
  static bool get hasValidFirebaseConfig => 
    firebaseApiKey.isNotEmpty && 
    firebaseProjectId.isNotEmpty;
}
