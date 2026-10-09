class CategoryModel {
  final String categoria;

  CategoryModel({required this.categoria});

  factory CategoryModel.fromJson(dynamic json) {
    if (json is Map) {
      final value =
          json['categoria'] ??
          json['Categoría'] ??
          json['category'] ??
          json['name'] ??
          '';
      return CategoryModel(categoria: value.toString().trim());
    } else if (json is List && json.isNotEmpty) {
      return CategoryModel(categoria: json[0].toString().trim());
    } else if (json is String) {
      return CategoryModel(categoria: json.trim());
    }
    return CategoryModel(categoria: '');
  }

  Map<String, dynamic> toJson() => {'categoria': categoria};
}
