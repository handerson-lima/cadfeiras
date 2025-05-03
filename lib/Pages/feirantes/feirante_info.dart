import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Model/feirante.dart';
import '../cadastro feirantes/Components/feiras_selection.dart';
import '../cadastro feirantes/Components/produtos_selection.dart';
import '../../services/feirante_service.dart';

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
  final FeiranteService _feiranteService = FeiranteService();

  @override
  void initState() {
    super.initState();
    _feirasSelecionadas = Set.from(widget.feirante.feirasSelecionadas);
    _produtosSelecionados = Set.from(widget.feirante.produtosSelecionados);
    _quantidadeBancasController = TextEditingController(text: widget.feirante.quantidadeBancas.toString());
    _localColetaController = TextEditingController(text: widget.feirante.localColeta);
  }

  Future<void> _submit() async {
    final updatedFeirante = Feirante(
      cpf: widget.feirante.cpf,
      nome: widget.feirante.nome,
      telefone: widget.feirante.telefone,
      cidade: widget.feirante.cidade,
      foto: widget.feirante.foto,
      endereco: widget.feirante.endereco,
      complemento: widget.feirante.complemento,
      dependentesQuantidade: widget.feirante.dependentesQuantidade,
      feirasSelecionadas: _feirasSelecionadas,
      produtosSelecionados: _produtosSelecionados,
      quantidadeBancas: int.tryParse(_quantidadeBancasController.text) ?? widget.feirante.quantidadeBancas,
      localColeta: _localColetaController.text,
    );

    try {
      final success = await _feiranteService.updateFeirante(widget.feirante.cpf, updatedFeirante.toJson());
      if (success) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar feirante. Tente novamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar feirante: $e')),
      );
    }
  }

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
              Text(
                'INFORMAÇÕES DE ${widget.feirante.nome.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
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