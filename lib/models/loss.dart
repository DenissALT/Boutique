class Loss {
  final String id;
  final DateTime date;
  final String productId;
  final String productName;
  final int quantity;
  final String reason;
  final double totalCost;

  Loss({
    required this.id,
    required this.date,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.totalCost,
  });

  factory Loss.fromSheetRow(Map<String, String> row) {
    return Loss(
      id: row['id'] ?? '',
      date: DateTime.tryParse(row['date'] ?? '') ?? DateTime.now(),
      productId: row['productId'] ?? '',
      productName: row['productName'] ?? '',
      quantity: int.tryParse(row['quantity'] ?? '0') ?? 0,
      reason: row['reason'] ?? '',
      totalCost: double.tryParse(row['totalCost'] ?? '0') ?? 0,
    );
  }
}
