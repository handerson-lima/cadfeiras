import 'package:flutter/material.dart';
import '../../Model/feirante.dart';


class FeirantesCadastradosScreen extends StatelessWidget {
  const FeirantesCadastradosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados mockados de feirantes
    final List<Feirante> feirantes = [
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feirantes Cadastrados'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: feirantes.length,
        itemBuilder: (context, index) {
          final feirante = feirantes[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
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
                    builder: (context) => FeirasTrabalhadasScreen(feirante: feirante),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}