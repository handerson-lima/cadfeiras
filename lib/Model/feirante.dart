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
    required this.localColeta, String? dependentesSelecao,
  });

  get dependentesSelecao => null;
}