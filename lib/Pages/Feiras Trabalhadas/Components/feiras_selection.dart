import 'package:flutter/material.dart';

class FeirasSelectionWidget extends StatefulWidget {
  final Set<String> initialSelections;

  const FeirasSelectionWidget({super.key, required this.initialSelections});

  @override
  _FeirasSelectionWidgetState createState() => _FeirasSelectionWidgetState();
}

class _FeirasSelectionWidgetState extends State<FeirasSelectionWidget> {
  late Set<String> _feirasSelecionadas;

  // Lista de feiras disponíveis
  final List<Map<String, String>> _feiras = [
    {'nome': 'ALECRIM', 'regiao': 'LESTE'},
    {'nome': 'ALIANÇA', 'regiao': 'NORTE'},
    {'nome': 'CARRASCO', 'regiao': 'LESTE'},
    {'nome': 'CIDADE DA ESPERANÇA', 'regiao': 'OESTE'},
    {'nome': 'CIDADE PRAIA', 'regiao': 'NORTE'},
    {'nome': 'FELIPE CAMARÃO', 'regiao': 'OESTE'},
    {'nome': 'IGAPÓ', 'regiao': 'NORTE'},
    {'nome': 'LAGOA SECA', 'regiao': 'SUL'},
    {'nome': 'MÃE LUIZA', 'regiao': 'LESTE'},
    {'nome': 'NOVA NATAL', 'regiao': 'NORTE'},
    {'nome': 'NOVA REPÚBLICA', 'regiao': 'NORTE'},
    {'nome': 'PANORAMA', 'regiao': 'NORTE'},
    {'nome': 'PAJUÇARA', 'regiao': 'NORTE'},
    {'nome': 'PARQUE DOS COQUEIROS', 'regiao': 'NORTE'},
    {'nome': 'PLANALTO', 'regiao': 'OESTE'},
    {'nome': 'PIRANGI', 'regiao': 'SUL'},
    {'nome': 'QUINTAS', 'regiao': 'LESTE'},
    {'nome': 'ROCAS', 'regiao': 'LESTE'},
    {'nome': 'SANTA CATARINA', 'regiao': 'NORTE'},
  ];

  @override
  void initState() {
    super.initState();
    // Copiar seleções iniciais
    _feirasSelecionadas = Set.from(widget.initialSelections);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Feiras'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _feiras.map((feira) {
            final feiraKey = '${feira['nome']} (${feira['regiao']})';
            return CheckboxListTile(
              title: Text(feiraKey),
              value: _feirasSelecionadas.contains(feiraKey),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _feirasSelecionadas.add(feiraKey);
                  } else {
                    _feirasSelecionadas.remove(feiraKey);
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
            Navigator.pop(context, _feirasSelecionadas); // Salvar
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}