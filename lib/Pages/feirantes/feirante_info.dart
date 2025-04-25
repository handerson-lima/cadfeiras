import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Model/feirante.dart';
import '../cadastro feirantes/Components/feiras_selection.dart';
import '../cadastro feirantes/Components/produtos_selection.dart';

class FeiranteInfoScreen extends StatefulWidget {
  final Feirante feirante;

  const FeiranteInfoScreen({super.key, required this.feirante});

  @override
  _FeiranteInfoScreenState createState() => _FeiranteInfoScreenState();
}

class _FeiranteInfoScreenState extends State<FeiranteInfoScreen> {
  late Set<String> _feirasSelecionadas;
  late Set<String> _produtosSelecionados;
  late TextEditingController _quantidadeBancasController;
  late TextEditingController _localColetaController;

  @override
  void initState() {
    super.initState();
    // Inicializar com os valores do feirante
    _feirasSelecionadas = Set.from(widget.feirante.feirasSelecionadas);
    _produtosSelecionados = Set.from(widget.feirante.produtosSelecionados);
    _quantidadeBancasController = TextEditingController(text: widget.feirante.quantidadeBancas.toString());
    _localColetaController = TextEditingController(text: widget.feirante.localColeta);
  }

  void _submit() {
    // Simular salvamento das feiras, produtos, quantidade de bancas e local de coleta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Informações atualizadas para ${widget.feirante.nome}:\n'
              'Feiras em que atua: ${_feirasSelecionadas.isEmpty ? "Nenhuma" : _feirasSelecionadas.join(", ")}\n'
              'Produtos que comercializa: ${_produtosSelecionados.isEmpty ? "Nenhum" : _produtosSelecionados.join(", ")}\n'
              'Quantidade de bancas: ${_quantidadeBancasController.text.isEmpty ? "Não informado" : _quantidadeBancasController.text}\n'
              'Local da coleta: ${_localColetaController.text.isEmpty ? "Não informado" : _localColetaController.text}',
        ),
      ),
    );
    Navigator.pop(context);
  }

  // Abrir o diálogo de seleção de feiras
  Future<void> _selectFeiras() async {
    final selectedFeiras = await showDialog<Set<String>>(
      context: context,
      builder: (context) => FeirasSelectionWidget(
        initialSelections: _feirasSelecionadas,
      ),
    );

    if (selectedFeiras != null) {
      setState(() {
        _feirasSelecionadas.clear();
        _feirasSelecionadas.addAll(selectedFeiras);
      });
    }
  }

  // Abrir o diálogo de seleção de produtos
  Future<void> _selectProdutos() async {
    final selectedProdutos = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ProdutosSelectionWidget(
        initialSelections: _produtosSelecionados,
      ),
    );

    if (selectedProdutos != null) {
      setState(() {
        _produtosSelecionados.clear();
        _produtosSelecionados.addAll(selectedProdutos);
      });
    }
  }

  @override
  void dispose() {
    _quantidadeBancasController.dispose();
    _localColetaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logomarca
              Image.asset(
                'assets/logo.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.store,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              // Título
              Text(
                'INFORMAÇÕES DE ${widget.feirante.nome.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              // Campo de seleção de feiras
              GestureDetector(
                onTap: _selectFeiras,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Feiras em que atua',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Exibir feiras selecionadas como chips
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _feirasSelecionadas.map((feira) {
                  return Chip(
                    label: Text(
                      feira,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _feirasSelecionadas.remove(feira);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Campo de seleção de produtos
              GestureDetector(
                onTap: _selectProdutos,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Produtos que comercializa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Exibir produtos selecionados como chips
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _produtosSelecionados.map((produto) {
                  return Chip(
                    label: Text(
                      produto,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _produtosSelecionados.remove(produto);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Campo Quantidade de bancas
              TextField(
                controller: _quantidadeBancasController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantidade de bancas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              // Campo Local da Coleta
              TextField(
                controller: _localColetaController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Local da Coleta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              // Botão Salvar
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 16),
              // Botão Voltar
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}