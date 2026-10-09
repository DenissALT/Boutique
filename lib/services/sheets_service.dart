import 'package:gsheets/gsheets.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/loss.dart';
import '../models/sale.dart';
import '../models/size.dart';
import '../models/category.dart';
import 'package:flutter/services.dart' show rootBundle;

class SheetsService {
  // Pega aquí las credenciales JSON descargadas de Google Cloud Console
  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;

  Worksheet? _sheetProducts;
  Worksheet? _sheetCustomers;
  Worksheet? _sheetSales;
  Worksheet? _sheetLosses;
  Worksheet? _sheetSizes;
  Worksheet? _sheetCategories;

  static const _spreadsheetId = '1mHDOxPKAySzVkqjyaj1dL8DdsFJqX8k41770ZCJn0AQ';
  Future<void> init() async {
    final String credentials = await rootBundle.loadString(
      'assets/credentials.json',
    );

    // Inicializar GSheets con las credenciales cargadas
    _gsheets = GSheets(credentials);
    _spreadsheet ??= await _gsheets!.spreadsheet(_spreadsheetId);
    _sheetProducts ??= _spreadsheet!.worksheetByTitle('Productos');
    _sheetCustomers ??= _spreadsheet!.worksheetByTitle('Clientes');
    _sheetSales ??= _spreadsheet!.worksheetByTitle('Ventas');
    _sheetLosses ??= _spreadsheet!.worksheetByTitle('Mermas');
    _sheetSizes ??= _spreadsheet!.worksheetByTitle('Talles');
    _sheetCategories = _spreadsheet!.worksheetByTitle('Categorias');
  }

  Future<List<CategoryModel>> fetchCategories() async {
    if (_sheetCategories == null) await init();

    if (_sheetCategories == null) {
      return [];
    }

    try {
      final rows = await _sheetCategories!.values.allRows();

      if (rows.isEmpty || rows.length <= 1) {
        return [];
      }

      final List<CategoryModel> categoriesList = [];

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].isNotEmpty) {
          final name = rows[i][0].toString().trim();
          if (name.isNotEmpty) {
            categoriesList.add(CategoryModel(categoria: name));
          }
        }
      }

      return categoriesList;
    } catch (e) {
      return [];
    }
  }

  // En tu SheetsService
  Future<List<SizeModel>> fetchSizes() async {
    if (_sheetSizes == null) await init();

    try {
      final mapList = await _sheetSizes!.values.map.allRows();
      if (mapList == null) return [];
      return mapList.map((json) => SizeModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
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

  Future<bool> updateProductStock(String productId, int newStock) async {
    if (_sheetProducts == null) await init();

    try {
      // 1. Obtenemos todas las filas de la hoja de Productos
      final rows = await _sheetProducts!.values.allRows();
      if (rows.isEmpty) return false;

      // 2. Buscamos en qué fila está el producto por su ID
      for (int i = 1; i < rows.length; i++) {
        // Empezamos en 1 omitiendo encabezados
        if (rows[i][0].toString() == productId) {
          // 3. Sobreescribimos la celda de la columna del Stock
          // (i + 1 porque las filas en Sheets son 1-based. Ajusta el número de columna según tu Excel/Sheets)
          return await _sheetProducts!.values.insertValue(
            newStock,
            column: 8, // Ejemplo: Columna 6 (F) si ahí está tu Stock
            row: i + 1,
          );
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addProduct(Product product) async {
    if (_sheetProducts == null) await init();
    return await _sheetProducts!.values.appendRow(product.toSheetRow());
  }

  Future<bool> updateProduct(Product product) async {
    if (_sheetProducts == null) await init();

    try {
      final rows = await _sheetProducts!.values.allRows();
      if (rows.isEmpty) return false;

      // Buscar la fila donde el ID coincida (omitimos encabezados en i = 1)
      for (int i = 1; i < rows.length; i++) {
        String idEnHoja = rows[i][0].toString().trim(); // Columna A (ID)

        if (idEnHoja == product.id.trim()) {
          // Sobreescribimos la fila completa (Fila en Sheets = i + 1)
          return await _sheetProducts!.values.insertRow(i + 1, [
            product.id,
            product.name,
            product.category,
            product.size,
            product.color,
            product.cost,
            product.price,
            product.stock,
            product.minStock,
            product.image,
            product.isActive,
          ]);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
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
