enum PhotoCategory {
  automaticColorized,
  guidedColorized,
  colorFiltered,
  convFiltered,
}

class PhotoModel {
  int id;
  int timestamp;
  String originalImagePath;
  String processedImagePath;
  PhotoCategory category;

  PhotoModel({
    required this.id,
    required this.timestamp,
    required this.originalImagePath,
    required this.processedImagePath,
    required this.category,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> json) => PhotoModel(
      id: json['id'],
      timestamp: json['timestamp'],
      originalImagePath: json['originalImagePath'],
      processedImagePath: json['processedImagePath'],
      category: PhotoCategory.values[json['category']]);

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'originalImagePath': originalImagePath,
        'processedImagePath': processedImagePath,
        'category': category.index,
      };
}
