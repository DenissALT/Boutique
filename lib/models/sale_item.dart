class SaleItem {
  final String productId;
  final String productName;
  final String size;
  final double unitCost;
  final double unitPrice;
  int quantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.unitCost,
    required this.unitPrice,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;
  double get totalCost => unitCost * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'size': size,
    'unitCost': unitCost,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    size: json['size'] ?? '',
    unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    quantity: json['quantity'] ?? 1,
  );
}
