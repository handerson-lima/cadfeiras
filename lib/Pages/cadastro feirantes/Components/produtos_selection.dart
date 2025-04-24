import 'package:flutter/material.dart';

class ProdutosSelectionWidget extends StatefulWidget {
  final Set<String> initialSelections;

  const ProdutosSelectionWidget({super.key, required this.initialSelections});

  @override
  _ProdutosSelectionWidgetState createState() => _ProdutosSelectionWidgetState();
}

class _ProdutosSelectionWidgetState extends State<ProdutosSelectionWidget> {
  late Set<String> _produtosSelecionados;

  // Lista de produtos disponíveis (baseada na imagem fornecida)
  final List<String> _produtos = [
    'HORTIFRUTI',
    'CARNES',
    'PESCADO/FRUTOS DO MAR',
    'TEMPEROS E CONDIMENTOS',
    'FERRAGENS E UTILIDADES',
    'QUEIJOS',
    'CEREAIS',
    'GOMA',
    'PRODUTOS DO SERTÃO',
    'BAZAR E ACESSÓRIOS',
    'REFEIÇÕES',
    'PLANTAS',
    'OVOS',
    'MILHO',
  ];

  @override
  void initState() {
    super.initState();
    // Copiar seleções iniciais
    _produtosSelecionados = Set.from(widget.initialSelections);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Produtos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _produtos.map((produto) {
            return CheckboxListTile(
              title: Text(produto),
              value: _produtosSelecionados.contains(produto),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _produtosSelecionados.add(produto);
                  } else {
                    _produtosSelecionados.remove(produto);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Cancelar
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _produtosSelecionados); // Salvar
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}