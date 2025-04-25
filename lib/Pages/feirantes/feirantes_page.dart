import 'package:flutter/material.dart';
import '../../Model/feirante.dart';
import 'feirante_info.dart';

class FeirantesCadastradosScreen extends StatefulWidget {
  const FeirantesCadastradosScreen({super.key});

  @override
  _FeirantesCadastradosScreenState createState() => _FeirantesCadastradosScreenState();
}

class _FeirantesCadastradosScreenState extends State<FeirantesCadastradosScreen> {
  final List<Feirante> _feirantes = [
    Feirante(
      nome: "Ana Silva",
      cpf: "123.456.789-00",
      telefone: "(84) 98765-4321",
      cidade: "Natal",
      endereco: "Rua das Flores, 123",
      complemento: "Apto 101",
      dependentesSelecao: "Sim",
      dependentesQuantidade: 2,
      feirasSelecionadas: {"ALECRIM (LESTE)", "PAJUÇARA (NORTE)"},
      produtosSelecionados: {"HORTIFRUTI", "QUEIJOS"},
      quantidadeBancas: 3,
      localColeta: "Mercado Central",
    ),
    Feirante(
      nome: "João Oliveira",
      cpf: "987.654.321-00",
      telefone: "(84) 91234-5678",
      cidade: "Parnamirim",
      endereco: "Av. Principal, 456",
      complemento: null,
      dependentesSelecao: "Não",
      dependentesQuantidade: null,
      feirasSelecionadas: {"CIDADE ALTA (CENTRO)"},
      produtosSelecionados: {"CARNES"},
      quantidadeBancas: 1,
      localColeta: "Feira Livre",
    ),
  ];

  List<Feirante> _filteredFeirantes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredFeirantes = _feirantes; // Inicialmente, exibe todos os feirantes
    _searchController.addListener(_filterFeirantes);
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
        title: const Text('Feirantes Cadastrados'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Barra de pesquisa com bordas arredondadas e efeito flutuante
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4, // Efeito flutuante
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
          // Lista de feirantes
          Expanded(
            child: ListView.builder(
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
                          errorBuilder: (context, error, stackTrace) => const Icon(
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