import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/customer.dart'; // Tu modelo existente
import '../services/sheets_service.dart';

class CustomersView extends StatefulWidget {
  final SheetsService sheetsService;
  const CustomersView({super.key, required this.sheetsService});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  // Datos de prueba usando tu constructor
  final List<Customer> _customers = [];
  String _searchQuery = '';
  bool _isLoading = true;
  void _openCustomerForm([Customer? customerToEdit]) {
    final isEditing = customerToEdit != null;

    showCustomerDialog(
      context,
      customer: customerToEdit,
      onSave: (customerData) async {
        setState(() {
          if (isEditing) {
            final index = _customers.indexWhere((c) => c.id == customerData.id);
            if (index != -1) {
              _customers[index] = customerData;
            } //mas bien este es el que guarda si no encuentra nada
          } else {
            _customers.add(customerData);
          }
        });
        bool success = false;
        if (isEditing) {
          success = await SheetsService().addCustomer(customerData);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? (isEditing ? 'Cliente actualizado' : 'Cliente registrado')
                    : 'Error al conectar con Google Sheets',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers(); // Inicia la carga de datos
  }

  // 3. Función auxiliar asíncrona para consultar Sheets
  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true; // Aseguramos que muestre el spinner de carga
    });
    try {
      final customersFromSheet = await SheetsService().fetchCustomers();
      if (mounted) {
        setState(() {
          _customers.clear(); // Vacías la lista existente
          _customers.addAll(
            customersFromSheet,
          ); // Le metes los elementos nuevos
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtramos únicamente los activos y los que coincidan con la búsqueda
    final filteredCustomers = _customers.where((c) {
      if (!c.isActive) return false;
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CABECERA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Directorio de Clientes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Registro y gestión de clientes frecuentes.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC026D3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => showCustomerDialog(
                  context,
                  customer: null, // null para nuevo cliente
                  onSave: (newCustomer) async {
                    final success = await SheetsService().addCustomer(
                      newCustomer,
                    );
                    if (success) {
                      final updatedList = await SheetsService()
                          .fetchCustomers();
                      final jsonlist = updatedList
                          .map((c) => c.toSheetRow())
                          .toList();

                      setState(() {
                        _customers.clear(); // Vacía la lista actual
                        _customers.addAll(
                          updatedList,
                        ); // Le agrega todos los elementos traídos de Sheets
                      });
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Cliente registrado!'
                                : 'Error al registrar cliente',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Registrar Cliente'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. BUSCADOR
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Buscar cliente por nombre o teléfono...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. GRID DE CLIENTES A PANTALLA COMPLETA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCustomers.isEmpty
                ? const Center(
                    child: Text(
                      'No hay clientes registrados.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(
                                          0xFFC026D3,
                                        ).withOpacity(0.1),
                                        child: Text(
                                          customer.name.isNotEmpty
                                              ? customer.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(0xFFC026D3),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📞 ${customer.phone}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (customer.notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${customer.notes}"',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _customers.removeWhere(
                                        (c) => c.id == customer.id,
                                      );
                                    });
                                  },
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
    );
  }
}

void showCustomerDialog(
  BuildContext context, {
  Customer? customer,
  required Function(Customer) onSave,
}) {
  final isEditing = customer != null;

  final nameController = TextEditingController(
    text: isEditing ? customer.name : '',
  );
  final phoneController = TextEditingController(
    text: isEditing ? customer.phone : '',
  );
  final notesController = TextEditingController(
    text: isEditing ? customer.notes : '',
  );

  final formKey = GlobalKey<FormState>();
  showDialog(
    context: context,
    barrierDismissible: true,

    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Cliente' : 'Registrar Cliente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // Nombre
                const Text(
                  'Nombre Completo *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 13),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                  decoration: InputDecoration(
                    hintText: 'Ej: María López',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Teléfono
                const Text(
                  'Teléfono / WhatsApp *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                  decoration: InputDecoration(
                    hintText: 'Ej: 0981123456',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notas
                const Text(
                  'C.I / RUC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: notesController,
                  style: const TextStyle(fontSize: 13),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC026D3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final updatedCustomer = Customer(
                            id: isEditing
                                ? customer.id
                                : DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            debt: isEditing ? customer.debt : 0,
                            notes: notesController.text.trim(),
                            isActive: isEditing ? customer.isActive : true,
                          );
                          onSave(updatedCustomer); // Envía los datos

                          Navigator.of(dialogContext).pop(); // Cierra el modal
                        }
                      },
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
