import 'package:gsheets/gsheets.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/loss.dart';
import '../models/sale.dart';

class SheetsService {
  // Pega aquí las credenciales JSON descargadas de Google Cloud Console


  

  late final GSheets _gsheets;
  Spreadsheet? _spreadsheet;

  Worksheet? _sheetProducts;
  Worksheet? _sheetCustomers;
  Worksheet? _sheetSales;
  Worksheet? _sheetLosses;

  Future<void> init() async {
    _gsheets = GSheets(_credentials);
    _spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);

    _sheetProducts = _spreadsheet!.worksheetByTitle('Productos');
    _sheetCustomers = _spreadsheet!.worksheetByTitle('Clientes');
    _sheetSales = _spreadsheet!.worksheetByTitle('Ventas');
    _sheetLosses = _spreadsheet!.worksheetByTitle('Mermas');
  }

  // --- PRODUCTOS ---
  Future<List<Product>> fetchProducts() async {
    if (_sheetProducts == null) await init();
    final rows = await _sheetProducts!.values.map.allRows();
    if (rows == null) return [];

    return rows
        .map((r) => Product.fromSheetRow(r))
        .where((p) => p.isActive)
        .toList();
  }

  Future<bool> addProduct(Product product) async {
    if (_sheetProducts == null) await init();
    return await _sheetProducts!.values.appendRow(product.toSheetRow());
  }

  // --- CLIENTES ---
  Future<List<Customer>> fetchCustomers() async {
    if (_sheetCustomers == null) await init();
    final rows = await _sheetCustomers!.values.map.allRows();
    if (rows == null) return [];

    return rows
        .map((c) => Customer.fromSheetRow(c))
        .where((c) => c.isActive)
        .toList();
  }

  Future<bool> addCustomer(Customer customer) async {
    if (_sheetCustomers == null) await init();
    return await _sheetCustomers!.values.appendRow(customer.toSheetRow());
  }

  // --- VENTAS ---
  Future<bool> recordSale({
    required String id,
    required String customerId,
    required String customerName,
    required String paymentMethod,
    required String itemsJson,
    required double subtotal,
    required double discount,
    required double total,
    required double profit,
  }) async {
    if (_sheetSales == null) await init();
    return await _sheetSales!.values.appendRow([
      id,
      DateTime.now().toIso8601String(),
      customerId,
      customerName,
      paymentMethod,
      itemsJson,
      subtotal,
      discount,
      total,
      profit,
    ]);
  }

  // --- CONSULTAR HISTORIAL DE VENTAS ---
  Future<List<Sale>> fetchSales() async {
    if (_sheetSales == null) await init();
    final rows = await _sheetSales!.values.map.allRows();
    if (rows == null) return [];

    return rows.map((r) => Sale.fromSheetRow(r)).toList();
  }

  // --- REGISTRAR MERMA ---
  Future<bool> recordLoss(Loss loss) async {
    if (_sheetLosses == null) await init();
    return await _sheetLosses!.values.appendRow([
      loss.id,
      loss.date.toIso8601String(),
      loss.productId,
      loss.productName,
      loss.quantity,
      loss.reason,
      loss.totalCost,
    ]);
  }

  // --- CONSULTAR MERMAS ---
  Future<List<Loss>> fetchLosses() async {
    if (_sheetLosses == null) await init();
    final rows = await _sheetLosses!.values.map.allRows();
    if (rows == null) return [];

    return rows.map((r) => Loss.fromSheetRow(r)).toList();
  }
}
