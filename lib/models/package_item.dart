class PackageItem {
  final String id;
  final String description;
  final double? weight;
  final String? dimensions;
  final List<String> imageUrls;
  final String? specialInstructions;
  final bool isUploadingPhotos;

  PackageItem({
    required this.id,
    required this.description,
    this.weight,
    this.dimensions,
    this.imageUrls = const [],
    this.specialInstructions,
    this.isUploadingPhotos = false,
  });

  PackageItem copyWith({
    String? id,
    String? description,
    double? weight,
    String? dimensions,
    List<String>? imageUrls,
    String? specialInstructions,
    bool? isUploadingPhotos,
  }) {
    return PackageItem(
      id: id ?? this.id,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      imageUrls: imageUrls ?? this.imageUrls,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isUploadingPhotos: isUploadingPhotos ?? this.isUploadingPhotos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'weight': weight,
      'dimensions': dimensions,
      'imageUrls': imageUrls,
      'specialInstructions': specialInstructions,
    };
  }

  factory PackageItem.fromMap(Map<String, dynamic> map) {
    return PackageItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      weight: map['weight']?.toDouble(),
      dimensions: map['dimensions'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      specialInstructions: map['specialInstructions'],
    );
  }

  double get totalWeight => weight ?? 0.0;
  
  String get weightDisplay => weight != null ? '${weight!.toStringAsFixed(1)} lbs' : 'Not specified';
  
  String get dimensionsDisplay => dimensions ?? 'Not specified';
  
  int get imageCount => imageUrls.length;
}
