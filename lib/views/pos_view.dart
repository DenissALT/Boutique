import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale_item.dart';
import '../services/sheets_service.dart';
import 'package:intl/intl.dart';
import 'customers_view.dart';

class PosView extends StatefulWidget {
  final SheetsService sheetsService;
  const PosView({super.key, required this.sheetsService});

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  List<Product> _products = [];
  List<Customer> _customers = [];
  final List<SaleItem> _cart = [];

  Customer? _selectedCustomer;
  String _paymentMethod = 'Efectivo';
  double _discount = 0;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prods = await widget.sheetsService.fetchProducts();
    final custs = await widget.sheetsService.fetchCustomers();
    setState(() {
      _products = prods;
      _customers = custs;
      _isLoading = false;
    });
  }

  void _addToCart(Product product, {int quantityToAdd = 1}) {
    if (product.stock <= 0) return;

    final index = _cart.indexWhere((item) => item.productId == product.id);
    if (index != -1) {
      if (_cart[index].quantity + quantityToAdd <= product.stock) {
        setState(() => _cart[index].quantity += quantityToAdd);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock máximo alcanzado para este producto'),
          ),
        );
      }
    } else {
      setState(() {
        _cart.add(
          SaleItem(
            productId: product.id,
            productName: product.name,
            size: product.size,
            unitCost: product.cost,
            unitPrice: product.price,
            quantity: quantityToAdd,
          ),
        );
      });
    }
  }

  void _updateQuantity(SaleItem item, int delta) {
    final product = _products.firstWhere((p) => p.id == item.productId);
    final newQty = item.quantity + delta;

    if (newQty <= 0) {
      setState(() => _cart.remove(item));
    } else if (newQty <= product.stock) {
      setState(() => item.quantity = newQty);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay suficiente stock disponible')),
      );
    }
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _processSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    if (_paymentMethod == 'Fiado' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para ventas Fiadas debes seleccionar un cliente registrado',
          ),
        ),
      );
      return;
    }

    final totalCost = _cart.fold(0.0, (sum, item) => sum + item.totalCost);
    final profit = _total - totalCost;
    final saleId =
        'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final itemsJson = jsonEncode(_cart.map((e) => e.toJson()).toList());

    final success = await widget.sheetsService.recordSale(
      id: saleId,
      customerId: _selectedCustomer?.id ?? '',
      customerName: _selectedCustomer?.name ?? '',
      paymentMethod: _paymentMethod,
      itemsJson: itemsJson,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      profit: profit,
    );

    if (success && mounted) {
      for (var item in _cart) {
        final index = _products.indexWhere((p) => p.id == item.productId);
        if (index != -1) {
          int newStock = _products[index].stock - item.quantity;
          if (newStock < 0) newStock = 0;
          await widget.sheetsService.updateProductStock(
            item.productId,
            newStock,
          );
        }
      }

      final updatedProducts = await widget.sheetsService.fetchProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta #$saleId registrada con éxito')),
      );

      setState(() {
        _products = updatedProducts;
        _cart.clear();
        _discount = 0;
        _selectedCustomer = null;
      });
    }
  }

  // MUESTRA LA IMAGEN Y DETALLES EN GRANDE
  void _showImageDialog(BuildContext context, Product product) {
    final currencyFormat = NumberFormat('#,##0', 'es_PY');
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: product.image != null && product.image!.isNotEmpty
                      ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoría: ${product.category}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Talla: ${product.size} | Color: ${product.color}'),
                      Text(
                        'Stock disponible: ${product.stock} un.',
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₲ ${currencyFormat.format(product.price)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC026D3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC026D3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: product.stock > 0
                      ? () {
                          _addToCart(product);
                          Navigator.pop(dialogCtx);
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar al Carrito'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'es_PY');
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // BÚSQUEDA MULTICRITERIO (Nombre, Categoría, Talla y Color)
    final filteredProducts = _products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.size.toLowerCase().contains(q) ||
          p.color.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CATÁLOGO DE PRODUCTOS (Ocupa todo el resto del espacio horizontal)
          Expanded(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar prendas, tallas, categorías, color...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      return Card(
                        color: Colors.white,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.black.withOpacity(0.2),
                        child: InkWell(
                          onTap: () => _showImageDialog(
                            context,
                            p,
                          ), // ABRIR VISTA GRANDE EN CLIC
                          child: Stack(
                            children: [
                              // IMAGEN Y GRADIENTE
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        p.image != null && p.image!.isNotEmpty
                                            ? Image.network(
                                                p.image!,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                      if (progress == null)
                                                        return child;
                                                      return Container(
                                                        color: Colors.grey[100],
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.25),
                                                Colors.black.withOpacity(0.65),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // INFORMACIÓN Y BOTÓN
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.92,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              p.category.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Talla: ${p.size} | Color: ${p.color}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                      const Spacer(),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.stock > 0
                                              ? Colors.black.withOpacity(0.6)
                                              : Colors.red.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          p.stock > 0
                                              ? '${p.stock} un.'
                                              : 'Agotado',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₲ ${currencyFormat.format(p.price)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          IconButton.filled(
                                            style: IconButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFC026D3,
                                              ),
                                            ),
                                            onPressed: p.stock > 0
                                                ? () => _addToCart(p)
                                                : null,
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 2. SECCIÓN DEL CARRITO (ANCHO FIJO)
          SizedBox(
            width: 320, // ANCHO CONTROLADO
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carrito de Compras',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SELECCIÓN DE CLIENTE
                    Row(
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFC026D3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            searchConsumerDialog(
                              context,
                              customers: _customers,
                              onSelect: (selectedCustomer) {
                                setState(() {
                                  _selectedCustomer = selectedCustomer;
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.search, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            enabled: false,
                            controller: TextEditingController(
                              text: _selectedCustomer != null
                                  ? _selectedCustomer!.name
                                  : 'Cliente Ocasional',
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => showCustomerDialog(
                            context,
                            customer: null,
                            onSave: (newCustomer) async {},
                          ),
                          icon: const Icon(Icons.person_add, size: 18),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // LISTA DE ÍTEMS CON CONTROLES - / +
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // BANDERITAS INCREMENTO / DECREMENTO
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              _updateQuantity(item, -1),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _updateQuantity(item, 1),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₲ ${currencyFormat.format(item.totalPrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(
                          '₲ ${currencyFormat.format(_subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Descuento (₲)',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        SizedBox(
                          width: 90,
                          height: 34,
                          child: TextField(
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '0',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _discount = double.tryParse(val) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      isDense: true,
                      iconSize: 18,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      items:
                          ['Efectivo', 'Transferencia / QR', 'Tarjeta', 'Fiado']
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₲ ${currencyFormat.format(_total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC026D3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC026D3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _processSale,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text(
                          'Registrar Venta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void searchConsumerDialog(
  BuildContext context, {
  required List<Customer> customers,
  required Function(Customer) onSelect,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      // Creamos una copia local para ir filtrando
      List<Customer> filteredCustomers = List.from(customers);
      return AlertDialog(
        title: const Text('Buscar Cliente'),
        content: SizedBox(
          width: 420,
          //height: 450,
          // StatefulBuilder permite hacer setState() SOLO dentro de este dialogo
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  // A. Campo de búsqueda
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Escriba nombre o teléfono...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        // Filtramos la lista en tiempo real por nombre o teléfono
                        filteredCustomers = customers
                            .where(
                              (c) =>
                                  c.name.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ) ||
                                  c.phone.contains(query),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // B. Lista envuelta en Expanded (justo como adivinaste)
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron clientes',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final initial = customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?';

                              bool isHovered = false;

                              return StatefulBuilder(
                                builder: (context, setTileState) {
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) =>
                                        setTileState(() => isHovered = true),
                                    onExit: (_) =>
                                        setTileState(() => isHovered = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 100,
                                      ),
                                      margin: EdgeInsets.only(
                                        bottom: 8,
                                        /*top: isHovered
                                            ? 0
                                            : 2,*/
                                        // Hace el efecto de elevación cambiando el margen
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHovered
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3)
                                            : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isHovered
                                                ? Colors.black.withOpacity(0.08)
                                                : Colors.black.withOpacity(
                                                    0.03,
                                                  ),
                                            //blurRadius: isHovered ? 8 : 4,
                                            /*offset: isHovered
                                                ? const Offset(0, 4)
                                                : const Offset(0, 2),*/
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          onSelect(customer);
                                          Navigator.of(dialogContext).pop();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                                child: Text(
                                                  initial,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      customer.name,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                        color: isHovered
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                            : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.phone_outlined,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          customer
                                                                  .phone
                                                                  .isNotEmpty
                                                              ? customer.phone
                                                              : 'Sin teléfono',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 16,
                                                color: isHovered
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.grey[400],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}


/*
child: DropdownButtonFormField<Customer?>(
                            decoration: InputDecoration(
                              labelText: 'Cliente',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: _selectedCustomer,
                            items: [
                              const DropdownMenuItem<Customer?>(
                                value: null,
                                child: Text(''),
                              ),
                              ..._customers.map(
                                (c) => DropdownMenuItem<Customer?>(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedCustomer = val),
                          ),
*/