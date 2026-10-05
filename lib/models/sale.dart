import 'dart:convert';
import 'sale_item.dart';

class Sale {
  final String id;
  final String customerId;
  final String customerName;
  final String paymentMethod;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final double profit;
  final String date;

  Sale({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.profit,
    required this.date,
  });

  // Constructor para mapear la fila de la celda de Google Sheets a Objeto Sale
  // En lib/models/sale.dart

  factory Sale.fromSheetRow(Map<String, dynamic> row) {
    List<SaleItem> itemsList = [];

    final itemsRaw = row['Items'] ?? row['items'] ?? row['Detalle'];
    if (itemsRaw != null && itemsRaw.toString().isNotEmpty) {
      try {
        List<dynamic> parsed = jsonDecode(itemsRaw.toString());
        itemsList = parsed.map((i) => SaleItem.fromJson(i)).toList();
      } catch (_) {}
    }

    return Sale(
      id: (row['ID'] ?? row['id'] ?? '').toString(),
      date: (row['Fecha'] ?? row['date'] ?? '').toString(),
      customerId: (row['ClienteID'] ?? row['customerId'] ?? '').toString(),
      customerName: (row['Cliente'] ?? row['customerName'] ?? 'Cliente General')
          .toString(),
      items: itemsList,
      paymentMethod: (row['MetodoPago'] ?? row['paymentMethod'] ?? 'Efectivo')
          .toString(),
      subtotal:
          double.tryParse(
            (row['Subtotal'] ?? row['subtotal'] ?? 0).toString(),
          ) ??
          0.0,
      discount:
          double.tryParse(
            (row['Descuento'] ?? row['discount'] ?? 0).toString(),
          ) ??
          0.0,
      total:
          double.tryParse((row['Total'] ?? row['total'] ?? 0).toString()) ??
          0.0,
      profit:
          double.tryParse((row['Ganancia'] ?? row['profit'] ?? 0).toString()) ??
          0.0,
    );
  }

  // Convierte el objeto Sale a Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'profit': profit,
      'date': date,
    };
  }

  // Crea un objeto Sale desde un Map/JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<SaleItem> itemsList = [];

    if (rawItems is String) {
      try {
        List<dynamic> parsed = jsonDecode(rawItems);
        itemsList = parsed.map((i) => SaleItem.fromJson(i)).toList();
      } catch (_) {}
    } else if (rawItems is List) {
      itemsList = rawItems.map((i) => SaleItem.fromJson(i)).toList();
    }

    return Sale(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? 'Cliente General',
      paymentMethod: json['paymentMethod'] ?? 'Efectivo',
      items: itemsList,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }
}
