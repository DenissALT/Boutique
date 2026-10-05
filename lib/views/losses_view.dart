import 'package:flutter/material.dart';
import '../models/loss.dart';
import '../services/sheets_service.dart';

class LossesView extends StatefulWidget {
  final SheetsService sheetsService;
  const LossesView({super.key, required this.sheetsService});

  @override
  State<LossesView> createState() => _LossesViewState();
}

class _LossesViewState extends State<LossesView> {
  List<Loss> _losses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLosses();
  }

  Future<void> _loadLosses() async {
    setState(() => _isLoading = true);
    final data = await widget.sheetsService.fetchLosses();
    setState(() {
      _losses = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Registro de Pérdidas y Mermas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Control de prendas dañadas, manchadas o con defectuosas', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.warning),
                label: const Text('Reportar Merma'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: _losses.length,
                itemBuilder: (context, index) {
                  final loss = _losses[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                    title: Text(loss.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Motivo: ${loss.reason} | Cantidad: ${loss.quantity} un.'),
                    trailing: Text(
                      '-₲ ${loss.totalCost.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
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