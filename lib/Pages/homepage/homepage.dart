import 'package:flutter/material.dart';
import '../../screens/relatorios/relatorios_screen.dart';
import '../Auth/login_page.dart';
import '../Dashboard/dashboard.dart';
import '../cadastro feirantes/feirante_cadastro.dart';
import '../feirantes/feirantes_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de widgets que serão exibidos na área de conteúdo
  final List<Widget> _screens = [
    DashboardScreen(),
    const FeiranteCadastroScreen(),
    const FeirantesCadastradosScreen(),
    const RelatoriosScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Fechar o Drawer em layout mobile após selecionar
    if (MediaQuery.of(context).size.width <= 1024) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar se é layout mobile (≤ 1024 pixels, inclui tablets na vertical)
    final isMobile = MediaQuery.of(context).size.width <= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CadFeiras'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: isMobile
            ? Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                print('Clicou no menu hamburguer');
                Scaffold.of(context).openDrawer();
              },
            );
          },
        )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Simular logout (pode integrar com backend)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(
        width: 250,
        child: Container(
          color: Colors.grey[200],
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                selected: _selectedIndex == 0,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => _onItemTapped(0),
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Novo Cadastro'),
                selected: _selectedIndex == 1,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => _onItemTapped(1),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Feirantes Cadastrados'),
                selected: _selectedIndex == 2,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => _onItemTapped(2),
              ),
            ],
          ),
        ),
      )
          : null,
      body: Row(
        children: [
          // Sidebar para desktop
          if (!isMobile)
            Container(
              width: 250,
              color: Colors.grey[200],
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    selected: _selectedIndex == 0,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Novo Cadastro'),
                    selected: _selectedIndex == 1,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Feirantes Cadastrados'),
                    selected: _selectedIndex == 2,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text('Relatórios'),
                    selected: _selectedIndex == 3,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(3)
                  ),
                ],
              ),
            ),
          // Área de Conteúdo
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}