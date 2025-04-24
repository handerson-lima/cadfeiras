import 'package:flutter/material.dart';
import '../../Model/feirante.dart';
import 'Components/feiras_selection.dart';

class FeirasTrabalhadasScreen extends StatefulWidget {
  final Feirante feirante;

  const FeirasTrabalhadasScreen({super.key, required this.feirante});

  @override
  _FeirasTrabalhadasScreenState createState() => _FeirasTrabalhadasScreenState();
}

class _FeirasTrabalhadasScreenState extends State<FeirasTrabalhadasScreen> {
  final Set<String> _feirasSelecionadas = {};

  void _submit() {
    // Simular salvamento das feiras selecionadas (pode integrar com backend)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feiras selecionadas para ${widget.feirante.nome}: ${_feirasSelecionadas.join(", ")}',
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
                'FEIRAS DE ${widget.feirante.nome.toUpperCase()}',
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