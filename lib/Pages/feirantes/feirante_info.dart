import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data'; // Import para Uint8List
import 'package:image_picker/image_picker.dart'; // Import para ImagePicker

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
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _cidadeController;
  late TextEditingController _enderecoController;
  late TextEditingController _complementoController;
  late TextEditingController _dependentesQuantidadeController;
  late TextEditingController _quantidadeBancasController;
  late TextEditingController _localColetaController;

  // Alterado o tipo para Uint8List?
  Uint8List? _selectedImageBytes; // Para armazenar os bytes da nova imagem selecionada

  final FeiranteService _feiranteService = FeiranteService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _feirasSelecionadas = Set.from(widget.feirante.feirasSelecionadas);
    _produtosSelecionados = Set.from(widget.feirante.produtosSelecionados);
    _nomeController = TextEditingController(text: widget.feirante.nome);
    _telefoneController = TextEditingController(text: widget.feirante.telefone);
    _cidadeController = TextEditingController(text: widget.feirante.cidade);
    _enderecoController = TextEditingController(text: widget.feirante.endereco);
    _complementoController = TextEditingController(text: widget.feirante.complemento);
    _dependentesQuantidadeController = TextEditingController(text: (widget.feirante.dependentesQuantidade ?? 0).toString());
    _quantidadeBancasController = TextEditingController(text: widget.feirante.quantidadeBancas.toString());
    _localColetaController = TextEditingController(text: widget.feirante.localColeta);

    // Inicializa com os bytes da foto existente, se houver
    _selectedImageBytes = widget.feirante.foto;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Lê o arquivo como bytes
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final updatedFeirante = Feirante(
      cpf: widget.feirante.cpf,
      nome: _nomeController.text,
      telefone: _telefoneController.text,
      cidade: _cidadeController.text,
      foto: _selectedImageBytes, // Agora passa os bytes da imagem
      endereco: _enderecoController.text,
      complemento: _complementoController.text,
      dependentesQuantidade: int.tryParse(_dependentesQuantidadeController.text) ?? 0,
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
              'Informações atualizadas para ${updatedFeirante.nome}:\n'
                  'Telefone: ${updatedFeirante.telefone}\n'
                  'Cidade: ${updatedFeirante.cidade}\n'
                  'Endereço: ${updatedFeirante.endereco}\n'
                  'Complemento: ${updatedFeirante.complemento}\n'
                  'Dependentes: ${updatedFeirante.dependentesQuantidade}\n'
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
    _nomeController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _enderecoController.dispose();
    _complementoController.dispose();
    _dependentesQuantidadeController.dispose();
    _quantidadeBancasController.dispose();
    _localColetaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Informações do Feirante'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Exibição da foto e botão de edição
              GestureDetector(
                onTap: _pickImage, // Chama a função para selecionar imagem
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  // Se houver bytes de imagem selecionados, use MemoryImage
                  // Caso contrário, se a foto original não for nula, assume que são bytes
                  // Caso contrário, mostra o ícone da câmera
                  backgroundImage: _selectedImageBytes != null
                      ? MemoryImage(_selectedImageBytes!) as ImageProvider<Object>?
                      : null,
                  child: _selectedImageBytes == null
                      ? Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.grey[600],
                  )
                      : null,
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
              TextField(
                controller: _nomeController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Nome do Feirante',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cidadeController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _enderecoController,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _complementoController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Complemento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _dependentesQuantidadeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantidade de Dependentes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),
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