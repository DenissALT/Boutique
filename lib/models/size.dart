class SizeModel {
  final String name;

  SizeModel({required this.name});

  factory SizeModel.fromJson(Map<String, dynamic> json) => SizeModel(
    name: json['name']?.toString() ?? json['size']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'name': name};
}
