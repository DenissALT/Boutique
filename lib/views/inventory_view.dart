import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/sheets_service.dart';

class InventoryView extends StatefulWidget {
  final SheetsService sheetsService;
  const InventoryView({super.key, required this.sheetsService});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<Product> _products = [];
  bool _isLoading = true;

  // Filtros
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  String _selectedSize = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.sheetsService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para renderizar imágenes tanto desde URL como desde Base64 local
  Widget _buildProductImage(String imageStr, {double size = 40}) {
    if (imageStr.isEmpty) {
      return Icon(
        Icons.checkroom,
        color: const Color(0xFFC026D3),
        size: size * 0.5,
      );
    }

    if (imageStr.startsWith('data:image')) {
      try {
        final base64Bytes = base64Decode(imageStr.split(',').last);
        return Image.memory(base64Bytes, fit: BoxFit.cover);
      } catch (_) {
        return Icon(
          Icons.checkroom,
          color: const Color(0xFFC026D3),
          size: size * 0.5,
        );
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.checkroom,
        color: const Color(0xFFC026D3),
        size: size * 0.5,
      ),
    );
  }

  // --- MODAL DE AGREGAR / EDITAR PRENDA ---
  void _openProductModal([Product? productToEdit]) {
    final isEditing = productToEdit != null;

    final nameCtrl = TextEditingController(
      text: isEditing ? productToEdit.name : '',
    );
    final colorCtrl = TextEditingController(
      text: isEditing ? productToEdit.color : '',
    );
    final costCtrl = TextEditingController(
      text: isEditing ? productToEdit.cost.toStringAsFixed(0) : '',
    );
    final priceCtrl = TextEditingController(
      text: isEditing ? productToEdit.price.toStringAsFixed(0) : '',
    );
    final stockCtrl = TextEditingController(
      text: isEditing ? productToEdit.stock.toString() : '1',
    );
    final minStockCtrl = TextEditingController(
      text: isEditing ? productToEdit.minStock.toString() : '2',
    );
    final imageCtrl = TextEditingController(
      text: isEditing ? productToEdit.image : '',
    );

    String categoryVal = isEditing ? productToEdit.category : 'Vestidos';
    String sizeVal = isEditing ? productToEdit.size : 'M';

    final categoriesList = [
      'Vestidos',
      'Blusas y Tops',
      'Pantalones y Jeans',
      'Chaquetas y Sacos',
      'Faldas',
      'Calzados',
      'Accesorios',
      'Otros',
    ];

    final sizesList = ['XS', 'S', 'M', 'L', 'XL', '36', '38', '40', 'Única'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String previewUrl = imageCtrl.text;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'Editar Prenda / Producto'
                        : 'Nueva Prenda / Producto',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de la Prenda
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Prenda *',
                          hintText: 'Ej: Vestido Seda Floral Midi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Categoría y Talla
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categoriesList.contains(categoryVal)
                                  ? categoryVal
                                  : categoriesList.first,
                              decoration: const InputDecoration(
                                labelText: 'Categoría *',
                                border: OutlineInputBorder(),
                              ),
                              items: categoriesList
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setModalState(() => categoryVal = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: sizesList.contains(sizeVal)
                                  ? sizeVal
                                  : sizesList[2],
                              decoration: const InputDecoration(
                                labelText: 'Talla *',
                                border: OutlineInputBorder(),
                              ),
                              items: sizesList
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setModalState(() => sizeVal = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Color / Tono
                      TextField(
                        controller: colorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Color / Tono',
                          hintText: 'Ej: Rosa Pastel, Negro, Beige',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Precio Costo y Venta
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Precio Costo (₲) *',
                                hintText: '120000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Precio Venta (₲) *',
                                hintText: '250000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Componente para Foto de Prenda (Carga desde Dispositivo o URL)
                      const Text(
                        'Foto de la Prenda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildProductImage(previewUrl, size: 64),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      38,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    // Redimensionamos la foto a un máximo de 250px de ancho/alto y 50% de calidad
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 250,
                                      maxHeight: 250,
                                      imageQuality: 50,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      final base64Img =
                                          'data:image/jpeg;base64,${base64Encode(bytes)}';

                                      // Verificación de seguridad en consola
                                      debugPrint(
                                        'Longitud Base64 comprimido: ${base64Img.length} caracteres',
                                      );

                                      setModalState(() {
                                        imageCtrl.text = base64Img;
                                        previewUrl = base64Img;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.upload_file,
                                    size: 18,
                                    color: Color(0xFFC026D3),
                                  ),
                                  label: const Text(
                                    'Subir desde dispositivo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: imageCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'O pega enlace https://...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {
                                      previewUrl = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stock e Alerta Stock Mínimo
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Inicial *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: minStockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Mínimo (Alerta) *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC026D3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;

                    final double cost = double.tryParse(costCtrl.text) ?? 0;
                    final double price = double.tryParse(priceCtrl.text) ?? 0;
                    final int stock = int.tryParse(stockCtrl.text) ?? 1;
                    final int minStock = int.tryParse(minStockCtrl.text) ?? 2;

                    final product = Product(
                      id: isEditing
                          ? productToEdit.id
                          : 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      name: nameCtrl.text,
                      category: categoryVal,
                      size: sizeVal,
                      color: colorCtrl.text,
                      cost: cost,
                      price: price,
                      stock: stock,
                      minStock: minStock,
                      image: imageCtrl.text,
                      isActive: true,
                    );

                    await widget.sheetsService.addProduct(product);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Prenda actualizada con éxito'
                                : 'Nueva prenda guardada en inventario',
                          ),
                        ),
                      );
                      _loadInventory();
                    }
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Guardar Producto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC026D3)),
      );
    }

    final categoriesList = [
      'Todas',
      ...{..._products.map((p) => p.category)},
    ];
    final sizesList = [
      'Todas',
      'XS',
      'S',
      'M',
      'L',
      'XL',
      '36',
      '38',
      '40',
      'Única',
    ];

    final filteredProducts = _products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.color.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategory == 'Todas' || p.category == _selectedCategory;
      final matchesSize = _selectedSize == 'Todas' || p.size == _selectedSize;

      return matchesSearch && matchesCat && matchesSize;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventario de Boutique',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de prendas, tallas, colores, precios y control de stock',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC026D3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openProductModal(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Nueva Prenda / Producto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por prenda, categoría, color...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: categoriesList.contains(_selectedCategory)
                        ? _selectedCategory
                        : 'Todas',
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: categoriesList
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    value: sizesList.contains(_selectedSize)
                        ? _selectedSize
                        : 'Todas',
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: sizesList
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              'Talla: $s',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSize = val!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay prendas en el inventario con los filtros seleccionados.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Producto / Prenda',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Categoría',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Talla / Color',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Costo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Venta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Ganancia u.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(
                              'Stock',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Acciones',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows: filteredProducts.map((p) {
                          final unitProfit = p.unitProfit;
                          final isLowStock = p.isLowStock;

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDF4FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildProductImage(
                                          p.image,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'ID: #${p.id}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.size,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      p.color.isEmpty ? '-' : p.color,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '₲ ${p.cost.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '₲ ${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '+₲ ${unitProfit.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? const Color(0xFFFFE4E6)
                                        : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${p.stock} un.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isLowStock
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed: () => _openProductModal(p),
                                      tooltip: 'Editar',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
