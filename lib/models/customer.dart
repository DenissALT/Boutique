class Customer {
  final String id;
  final String name;
  final String phone;
  double debt;
  final String notes;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.debt,
    required this.notes,
    this.isActive = true,
  });

  factory Customer.fromSheetRow(Map<String, String> row) {
    return Customer(
      id: row['id'] ?? '',
      name: row['name'] ?? '',
      phone: row['phone'] ?? '',
      debt: double.tryParse(row['debt'] ?? '0') ?? 0,
      notes: row['notes'] ?? '',
      isActive: row['is_active']?.toLowerCase() == 'true',
    );
  }

  List<dynamic> toSheetRow() {
    return [id, name, phone, debt, notes, isActive];
  }
}
