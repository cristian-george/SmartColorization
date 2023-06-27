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

  factory PhotoModel.fromMap(Map<String, dynamic> map) => PhotoModel(
      id: map['id'],
      timestamp: map['timestamp'],
      originalImagePath: map['originalImagePath'],
      processedImagePath: map['processedImagePath'],
      category: PhotoCategory.values[map['category']]);

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'originalImagePath': originalImagePath,
        'processedImagePath': processedImagePath,
        'category': category.index,
      };
}
