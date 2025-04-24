import 'package:flutter/material.dart';
import '../../Model/feirante.dart';

class FeirantesCadastradosScreen extends StatefulWidget {
  const FeirantesCadastradosScreen({super.key});

  @override
  _FeirantesCadastradosScreenState createState() => _FeirantesCadastradosScreenState();
}

class _FeirantesCadastradosScreenState extends State<FeirantesCadastradosScreen> {
  final _searchController = TextEditingController();
  List<Feirante> _feirantes = [];
  List<Feirante> _filteredFeirantes = [];

  @override
  void initState() {
    super.initState();
    // Dados simulados (substituir por dados do backend)
    _feirantes = [
      Feirante(
        nome: 'Ana Silva',
        cpf: '123.456.789-00',
        telefone: '(11) 98765-4321',
        cidade: 'São Paulo',
        foto: null,
      ),
      Feirante(
        nome: 'Bruno Oliveira',
        cpf: '987.654.321-00',
        telefone: '(21) 91234-5678',
        cidade: 'Rio de Janeiro',
        foto: null,
      ),
      Feirante(
        nome: 'Carla Souza',
        cpf: '456.789.123-00',
        telefone: '(31) 99876-5432',
        cidade: 'Belo Horizonte',
        foto: null,
      ),
    ];
    // Ordenar por nome
    _feirantes.sort((a, b) => a.nome.compareTo(b.nome));
    _filteredFeirantes = _feirantes;
    _searchController.addListener(_filterFeirantes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFeirantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFeirantes = _feirantes.where((feirante) {
        return feirante.nome.toLowerCase().contains(query) ||
            feirante.cpf.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Barra de Pesquisa
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Pesquisar por Nome ou CPF',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de Feirantes
          Expanded(
            child: _filteredFeirantes.isEmpty
                ? const Center(child: Text('Nenhum feirante encontrado'))
                : ListView.builder(
              itemCount: _filteredFeirantes.length,
              itemBuilder: (context, index) {
                final feirante = _filteredFeirantes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: feirante.foto != null
                          ? MemoryImage(feirante.foto!)
                          : null,
                      child: feirante.foto == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    title: Text(
                      feirante.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CPF: ${feirante.cpf}'),
                        Text('Telefone: ${feirante.telefone}'),
                        Text('Cidade: ${feirante.cidade}'),
                      ],
                    ),
                    onTap: () {
                    },
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