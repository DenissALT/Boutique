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
      //LossesView(sheetsService: widget.sheetsService),
      SalesHistoryView(sheetsService: widget.sheetsService),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color.fromRGBO(15, 23, 42, 1),
            // Se contrae obligatoriamente en Punto de Venta (_selectedIndex == 1)
            extended:
                MediaQuery.of(context).size.width > 800 && _selectedIndex != 1,
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
                icon: Icon(
                  Icons.pie_chart_outline,
                  color: Color(0xFF38BDF8),
                ), // Azul Cyan
                selectedIcon: Icon(Icons.pie_chart, color: Color(0xFF38BDF8)),
                label: Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.point_of_sale_outlined,
                  color: Color(0xFFE879F9),
                ), // Magenta / Rosa
                selectedIcon: Icon(
                  Icons.point_of_sale,
                  color: Color(0xFFE879F9),
                ),
                label: Text(
                  'Punto de Venta',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFFFACC15),
                ), // Amarillo Gold
                selectedIcon: Icon(Icons.inventory_2, color: Color(0xFFFACC15)),
                label: Text(
                  'Inventario',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.people_outline,
                  color: Color(0xFF4ADE80),
                ), // Verde Esmeralda
                selectedIcon: Icon(Icons.people, color: Color(0xFF4ADE80)),
                label: Text(
                  'Clientes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              /*NavigationRailDestination(
                icon: Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFFB923C),
                ), // Naranja Alerta
                selectedIcon: Icon(
                  Icons.warning_amber,
                  color: Color(0xFFFB923C),
                ),
                label: Text(
                  'Mermas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),*/
              NavigationRailDestination(
                icon: Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFFA78BFA),
                ), // Violeta / Púrpura
                selectedIcon: Icon(
                  Icons.receipt_long,
                  color: Color(0xFFA78BFA),
                ),
                label: Text(
                  'Historial',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
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
