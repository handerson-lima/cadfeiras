import 'dart:convert';
import 'package:flutter/material.dart';
import '../../Model/feirante.dart';
import '../../services/feirante_service.dart';
import 'feirante_info.dart';

class FeirantesCadastradosScreen extends StatefulWidget {
  const FeirantesCadastradosScreen({super.key});

  @override
  _FeirantesCadastradosScreenState createState() => _FeirantesCadastradosScreenState();
}

class _FeirantesCadastradosScreenState extends State<FeirantesCadastradosScreen> {
  List<Feirante> _feirantes = [];
  List<Feirante> _filteredFeirantes = [];
  final TextEditingController _searchController = TextEditingController();
  final FeiranteService _feiranteService = FeiranteService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFeirantes();
    _searchController.addListener(_filterFeirantes);
  }

  Future<void> _fetchFeirantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _feiranteService.fetchFeirantes();
      setState(() {
        _feirantes = records.map((record) {
          return Feirante(
            nome: record['nome'] ?? '',
            cpf: record['cpf'] ?? '',
            telefone: record['telefone'] ?? '',
            cidade: record['cidade'] ?? '',
            foto: record['foto'] != null ? base64Decode(record['foto']) : null,
            endereco: record['endereco'] ?? '',
            complemento: record['complemento'],
            dependentesQuantidade: record['dependentes_quantidade'] as int?,
            feirasSelecionadas: (record['feiras'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
            produtosSelecionados: (record['produtos'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
            quantidadeBancas: record['quantidade_bancas'] as int? ?? 0,
            localColeta: record['local_coleta'] ?? '',
          );
        }).toList();
        _filteredFeirantes = _feirantes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar feirantes: $e';
        print('Erro detalhado: $e');
        _isLoading = false;
      });
    }
  }

  void _filterFeirantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFeirantes = _feirantes;
      } else {
        _filteredFeirantes = _feirantes.where((feirante) {
          final nomeLower = feirante.nome.toLowerCase();
          final cpfLower = feirante.cpf.toLowerCase();
          return nomeLower.contains(query) || cpfLower.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
        'Feirantes Cadastrados',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Cor do texto do título
        ),
      ),
      backgroundColor: Colors.grey,
    ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome ou CPF',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _filteredFeirantes.isEmpty
                ? const Center(child: Text('Nenhum feirante encontrado.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredFeirantes.length,
              itemBuilder: (context, index) {
                final feirante = _filteredFeirantes[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: feirante.foto != null
                          ? ClipOval(
                        child: Image.memory(
                          feirante.foto!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(
                      feirante.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('CPF: ${feirante.cpf}'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeiranteInfoScreen(feirante: feirante),
                        ),
                      );
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