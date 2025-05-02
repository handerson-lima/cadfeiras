import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../Model/feirante.dart';
import 'Components/feiras_selection.dart';
import 'Components/produtos_selection.dart';

class FeiranteCadastroScreen extends StatefulWidget {
  const FeiranteCadastroScreen({super.key});

  @override
  _FeiranteCadastroScreenState createState() => _FeiranteCadastroScreenState();
}

class _FeiranteCadastroScreenState extends State<FeiranteCadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _complementoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _dependentesQuantidadeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _quantidadeBancasController = TextEditingController();
  final _localColetaController = TextEditingController();
  String? _dependentesSelecao;
  Uint8List? _imagemSelecionada;
  final Set<String> _feirasSelecionadas = {};
  final Set<String> _produtosSelecionados = {};

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _enderecoController.dispose();
    _complementoController.dispose();
    _cidadeController.dispose();
    _dependentesQuantidadeController.dispose();
    _telefoneController.dispose();
    _quantidadeBancasController.dispose();
    _localColetaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imagemSelecionada = bytes;
      });
    }
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Criar instância de Feirante com os dados coletados
      final feirante = Feirante(
        nome: _nomeController.text,
        cpf: _cpfController.text,
        telefone: _telefoneController.text,
        cidade: _cidadeController.text,
        foto: _imagemSelecionada,
        endereco: _enderecoController.text,
        complemento: _complementoController.text.isEmpty ? null : _complementoController.text,
        dependentesSelecao: _dependentesSelecao,
        dependentesQuantidade: _dependentesSelecao == 'Sim' && _dependentesQuantidadeController.text.isNotEmpty
            ? int.parse(_dependentesQuantidadeController.text)
            : null,
        feirasSelecionadas: _feirasSelecionadas,
        produtosSelecionados: _produtosSelecionados,
        quantidadeBancas: int.parse(_quantidadeBancasController.text),
        localColeta: _localColetaController.text,
      );

      // Simular ação de cadastro (pode integrar com backend)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cadastro de feirante bem-sucedido!\n'
                'Nome: ${feirante.nome}\n'
                'CPF: ${feirante.cpf}\n'
                'Endereço: ${feirante.endereco}\n'
                'Complemento: ${feirante.complemento ?? "Não informado"}\n'
                'Cidade: ${feirante.cidade}\n'
                'Dependentes: ${feirante.dependentesSelecao ?? "Não informado"}${feirante.dependentesSelecao == "Sim" ? " (Quantidade: ${feirante.dependentesQuantidade})" : ""}\n'
                'Telefone: ${feirante.telefone}\n'
                'Feiras em que atua: ${feirante.feirasSelecionadas.isEmpty ? "Nenhuma" : feirante.feirasSelecionadas.join(", ")}\n'
                'Produtos que comercializa: ${feirante.produtosSelecionados.isEmpty ? "Nenhum" : feirante.produtosSelecionados.join(", ")}\n'
                'Quantidade de bancas: ${feirante.quantidadeBancas}\n'
                'Local da coleta: ${feirante.localColeta}',
          ),
        ),
      );
      // Voltar para a tela de login
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CADASTRO DE FEIRANTES',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey,
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
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
              // Formulário
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo Foto
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imagemSelecionada == null
                            ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imagemSelecionada!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo CPF
                    TextFormField(
                      controller: _cpfController,
                      inputFormatters: [_cpfFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu CPF';
                        }
                        if (!_cpfFormatter.isFill()) {
                          return 'Insira um CPF válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Endereço
                    TextFormField(
                      controller: _enderecoController,
                      decoration: InputDecoration(
                        labelText: 'Endereço',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o endereço';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Complemento
                    TextFormField(
                      controller: _complementoController,
                      decoration: InputDecoration(
                        labelText: 'Complemento (opcional)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo Cidade
                    TextFormField(
                      controller: _cidadeController,
                      decoration: InputDecoration(
                        labelText: 'Cidade',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a cidade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo Dependentes
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _dependentesSelecao,
                            decoration: InputDecoration(
                              labelText: 'Dependentes',
                              prefixIcon: const Icon(Icons.family_restroom),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: ['Sim', 'Não'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _dependentesSelecao = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor, selecione uma opção';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_dependentesSelecao == 'Sim') ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _dependentesQuantidadeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantidade',
                                prefixIcon: const Icon(Icons.format_list_numbered),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Insira a quantidade';
                                }
                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return 'Insira um número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Campo Telefone
                    TextFormField(
                      controller: _telefoneController,
                      inputFormatters: [_telefoneFormatter],
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu telefone';
                        }
                        if (!_telefoneFormatter.isFill()) {
                          return 'Insira um telefone válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Campo de seleção de feiras
                    GestureDetector(
                      onTap: _selectFeiras,
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Feiras em que atua',
                            prefixIcon: const Icon(Icons.event),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
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
                            prefixIcon: const Icon(Icons.storefront),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
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
                    TextFormField(
                      controller: _quantidadeBancasController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Quantidade de bancas',
                        prefixIcon: const Icon(Icons.table_chart),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a quantidade de bancas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Campo Local da Coleta
                    TextFormField(
                      controller: _localColetaController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Local da Coleta',
                        prefixIcon: const Icon(Icons.add_business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o local da coleta';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Botão Cadastrar
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cadastrar'),
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