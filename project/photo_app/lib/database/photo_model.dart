enum PhotoCategory {
  automaticColorized,
  guidedColorized,
  colorFiltered,
  convFiltered,
}

class PhotoModel {
  int id;
  int timestamp;
  String path;
  PhotoCategory category;

  PhotoModel({
    required this.id,
    required this.timestamp,
    required this.path,
    required this.category,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> json) => PhotoModel(
      id: json['id'],
      timestamp: json['timestamp'],
      path: json['path'],
      category: PhotoCategory.values[json['category']]);

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'path': path,
        'category': category.index,
      };
}
