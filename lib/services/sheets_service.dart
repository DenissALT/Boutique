import 'package:gsheets/gsheets.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/loss.dart';
import '../models/sale.dart';
import '../models/size.dart';
import '../models/category.dart';

class SheetsService {
  // Pega aquí las credenciales JSON descargadas de Google Cloud Console
  static const _credentials = r'''{
  "type": "service_account",
  "project_id": "boutique-app-510417",
  "private_key_id": "f3109632617677c92a1588b21362ee7c60f9ef27",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDGcc3KmShE9fJy\nSG+0Ga1R3gsAX8aXDBfkLekQONrbH2ZwftwqZwy7myf678BF3Cz3AcHEvFobnr7C\nhlOtC+A78KuUgFUasR+mescD5BrTICaI3EMrAs/oV89VqHWqfpN4FrgxuacWwrKt\nUXtxZ7vav3vrSztWrr6FHj5j2ZKfiDH6rto/VYooBVcWVTf42S66cTF1WuKiOTn9\nSr1wLbX7TYn73d2AT/kYTOjlAypIbJ80c1ijXXXMn1B1som0j/9szO89NvPOGIoi\nAe6fYsmJtbCQDng0D62W6FDAj6byJv7qN92f7NSwj4s11gE99NAfLRNpIkas+HCs\nZ9W8PO+NAgMBAAECggEAKxwtggIYOLT6dL/OPoCmgaa8Wpoz5Pv8U7Zyj3LefqRZ\nZ35zu2V0I2xvOMktSq/sd8OisefeJmpr1AwE8Q6nqbXcvG/NrTUF5G9/PRXoiu2M\n2YYKNHWRr46l7NyiJUYGqNu8q5bCmQP2d4cAS3Bm47xeAg1vqGLhYj9h++SYAP5e\nK4PIHt/GkmjvlHqQbPSlLlMf/QLvP1Pfux3NmTxm4hyoOeZ3hdOtxsyoWhPrvRiF\n7wsDPIZHT1VMNFCWEAzibUh0RAZRAfGMYoXH48lYKMaY8GtL+CNx9AGxVe/N53Ui\nkpzuYCoaYUGa4JfEa3FzbafcH4jNHnlsQZZQW/FHcQKBgQDo8FV6uNa94WTLmj0m\nWh1xol9v+a9bL9NDnaxCAAf1ivegH1KOaSDwcpPjhcC2O3S0wg1s4etxF94avdWP\nV2JwOasTcB5V1cyXvcGmZ6ow/KRDpdZdPrcmjPlWOUSR7UrqNS6wO6s4NKarzVjP\n3opLm3TUd8TmstBvxMhqWS0KfQKBgQDaFzzkr3QRmlCnzB/21kVZarj26Bw/UNyO\nFp/k8gUNFkpfZK3qLi6q9S6VIWZo3b25aVdWegm+uyLT+LKMrWtMLCvXd9Z4CMjD\n2dt7cJhjbtnTB1pmzawZ/m/AnSWMtG4SlLlS6o+vGM2bSb93UvLWocB1StSga621\n6jJ+/HN2UQKBgQCOu+XFA0oio+A9mk9qFsIABXzxgk/fUljkD9OjxZ0a6oJ9zXOq\n6+RRMgRI4IaLo7cJo/bSB0Vb0UI5pKUd5m/dUJjxmjwcYJuzR4VH0DHLPqPxB8do\n76sOpkeKfCD2Qi8rgFcRih6KnEic8YFALp8TYTifkJxIuL1cH3qnH+mniQKBgQCk\nc2VdY9f39g7fmJJ5xLTiahEzTW8PZ2AIXJMRRlX8ulQ2fmqN7WkPTHZlyZu5c4s+\npmpPMRLsGZx3jk7EuXfxJlWg0iKMvML2u+4+tHaUc+AYurC2WFxv9WY7LcREx0FB\nDZh5J5pVBDT15bRUu92Vbr77MwQGO2vvgru0+ZPvIQKBgQDW68s7LWd8Bla2m6Dz\nsJwZW716eYp+GvMniYTe7GrOLf4PVUEQKOhk/1jT9K57cv5vVA/uE40xa26FAO4S\nmtlNnrDQIW36YQRVW3H+DknJ1V/sjoukVPMed0xpFlO5+5VWzaO8TtYhyTK+iQ+M\nJlaiHl0+KljpuMOkp49c6mKc0Q==\n-----END PRIVATE KEY-----\n",
  "client_email": "sheetbd@boutique-app-510417.iam.gserviceaccount.com",
  "client_id": "108873320774601807172",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sheetbd%40boutique-app-510417.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}''';

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
    _gsheets = GSheets(_credentials);
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
      print('DEBUG CATEGORÍAS: _sheetCategories sigue siendo NULL');
      return [];
    }

    try {
      final rows = await _sheetCategories!.values.allRows();
      print('DEBUG CATEGORÍAS - Filas crudas obtenidas de Sheets: $rows');

      if (rows.isEmpty || rows.length <= 1) {
        print('DEBUG CATEGORÍAS: La hoja está vacía o solo tiene encabezado');
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

      print(
        'DEBUG CATEGORÍAS - Resultado final mapeado: ${categoriesList.map((c) => c.categoria).toList()}',
      );
      return categoriesList;
    } catch (e) {
      print('DEBUG CATEGORÍAS - Excepción atrapada: $e');
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
      print('Error leyendo talles desde Sheets: $e');
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
      print('Error actualizando stock del producto: $e');
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
      print('Error actualizando producto: $e');
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
