import 'package:flutter/material.dart';
import 'services/sheets_service.dart';
import 'views/dashboard_view.dart';
import 'views/inventory_view.dart';
import 'views/pos_view.dart';
import 'views/customers_view.dart';
import 'views/losses_view.dart';
import 'views/sales_history_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sheetsService = SheetsService();
  await sheetsService.init();

  runApp(BoutiqueApp(sheetsService: sheetsService));
}

class BoutiqueApp extends StatelessWidget {
  final SheetsService sheetsService;
  const BoutiqueApp({super.key, required this.sheetsService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treinta Boutique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC026D3),
          primary: const Color(0xFFC026D3),
        ),
        useMaterial3: true,
      ),
      home: MainLayout(sheetsService: sheetsService),
    );
  }
}

class MainLayout extends StatefulWidget {
  final SheetsService sheetsService;
  const MainLayout({super.key, required this.sheetsService});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final views = [
      DashboardView(sheetsService: widget.sheetsService),
      PosView(sheetsService: widget.sheetsService),
      InventoryView(sheetsService: widget.sheetsService),
      CustomersView(sheetsService: widget.sheetsService),
      LossesView(sheetsService: widget.sheetsService),
      SalesHistoryView(sheetsService: widget.sheetsService),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF0F172A),
            extended: MediaQuery.of(context).size.width > 800,
            selectedIndex: _selectedIndex,
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
            selectedIconTheme: const IconThemeData(color: Color(0xFFE879F9)),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                label: Text('Punto de Venta'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Inventario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                label: Text('Clientes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                label: Text('Mermas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: Text('Historial'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: views[_selectedIndex]),
        ],
      ),
    );
  }
}
