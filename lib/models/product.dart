class Product {
  final String id;
  final String name;
  final String category;
  final String size;
  final String color;
  final double cost;
  final double price;
  int stock;
  final int minStock;
  final String image;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.color,
    required this.cost,
    required this.price,
    required this.stock,
    required this.minStock,
    this.isActive = true,
    this.image = '',
  });

  bool get isLowStock => stock <= minStock;
  double get unitProfit => price - cost;

  factory Product.fromSheetRow(Map<String, String> row) {
    return Product(
      id: row['id'] ?? '',
      name: row['name'] ?? '',
      category: row['category'] ?? '',
      size: row['size'] ?? '',
      color: row['color'] ?? '',
      cost: double.tryParse(row['cost'] ?? '0') ?? 0,
      price: double.tryParse(row['price'] ?? '0') ?? 0,
      stock: int.tryParse(row['stock'] ?? '0') ?? 0,
      minStock: int.tryParse(row['minStock'] ?? '2') ?? 2,
      image: row['image'] ?? '',
      isActive: row['is_active']?.toLowerCase() == 'true',
    );
  }

  List<dynamic> toSheetRow() {
    return [
      id,
      name,
      category,
      size,
      color,
      cost,
      price,
      stock,
      minStock,
      image,
      isActive,
    ];
  }
}
