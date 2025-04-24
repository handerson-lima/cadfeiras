import 'package:flutter/material.dart';
import '../Auth/login_page.dart';
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
    const FeiranteCadastroScreen(),
    const FeirantesCadastradosScreen(),
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
        title: const Text('Sistema de Feirantes'),
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
                leading: const Icon(Icons.person_add),
                title: const Text('Novo Cadastro'),
                selected: _selectedIndex == 0,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => _onItemTapped(0),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Feirantes Cadastrados'),
                selected: _selectedIndex == 1,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => _onItemTapped(1),
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
                    leading: const Icon(Icons.person_add),
                    title: const Text('Novo Cadastro'),
                    selected: _selectedIndex == 0,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Feirantes Cadastrados'),
                    selected: _selectedIndex == 1,
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _onItemTapped(1),
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