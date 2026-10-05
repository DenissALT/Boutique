import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/sheets_service.dart';

class SalesHistoryView extends StatefulWidget {
  final SheetsService sheetsService;
  const SalesHistoryView({super.key, required this.sheetsService});

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final data = await widget.sheetsService.fetchSales();
    setState(() {
      _sales = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de Ventas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Registro histórico de transacciones realizadas', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(Icons.receipt, color: Color(0xFFC026D3)),
                    ),
                    title: Text('Venta #${sale.id} - ${sale.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Método: ${sale.paymentMethod} | Items: ${sale.items.length}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₲ ${sale.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('+₲ ${sale.profit.toStringAsFixed(0)} ganancia', style: const TextStyle(color: Colors.green, fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}