import 'package:flutter/material.dart';
import '../services/sheets_service.dart';

class DashboardView extends StatefulWidget {
  final SheetsService sheetsService;
  const DashboardView({super.key, required this.sheetsService});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  double _totalSales = 0;
  double _netProfit = 0;
  double _pendingDebt = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final sales = await widget.sheetsService.fetchSales();
    final customers = await widget.sheetsService.fetchCustomers();

    double salesSum = 0;
    double profitSum = 0;
    for (var s in sales) {
      salesSum += s.total;
      profitSum += s.profit;
    }

    double debtSum = 0;
    for (var c in customers) {
      debtSum += c.debt;
    }

    setState(() {
      _totalSales = salesSum;
      _netProfit = profitSum;
      _pendingDebt = debtSum;
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
          const Text(
            'Dashboard Financiero',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _kpiCard(
                'Ventas Totales',
                '₲ ${_totalSales.toStringAsFixed(0)}',
                Colors.green.shade900,
              ),
              const SizedBox(width: 16),
              _kpiCard(
                'Ganancia Neta',
                '₲ ${_netProfit.toStringAsFixed(0)}',
                const Color(0xFFC026D3),
              ),
              const SizedBox(width: 16),
              _kpiCard(
                'Por Cobrar (Fiado)',
                '₲ ${_pendingDebt.toStringAsFixed(0)}',
                Colors.amber.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
