import 'dart:convert';
import 'dart:typed_data';

class Feirante {
  final String nome;
  final String cpf;
  final String telefone;
  final String cidade;
  final Uint8List? foto;
  final String endereco;
  final String? complemento;
  final int? dependentesQuantidade;
  final Set<String> feirasSelecionadas;
  final Set<String> produtosSelecionados;
  final int quantidadeBancas;
  final String localColeta;


  Feirante({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.cidade,
    this.foto,
    required this.endereco,
    this.complemento,
    this.dependentesQuantidade,
    this.feirasSelecionadas = const {},
    this.produtosSelecionados = const {},
    required this.quantidadeBancas,
    required this.localColeta,
  });

  get dataCadastro => null;

  Map<String, dynamic> toJson() {
    return {
      "nome": nome,
      "cpf": cpf,
      "telefone": telefone,
      "cidade": cidade,
      "endereco": endereco,
      "complemento": complemento,
      "dependentes_quantidade": dependentesQuantidade,
      "feiras": feirasSelecionadas.toList(),
      "produtos": produtosSelecionados.toList(),
      "quantidade_bancas": quantidadeBancas,
      "local_coleta": localColeta,
      "foto": foto != null ? base64Encode(foto!) : null,
    };
  }


}
