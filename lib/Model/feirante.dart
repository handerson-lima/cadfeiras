import 'dart:typed_data';
class Feirante {
  final String nome;
  final String cpf;
  final String telefone;
  final String cidade;
  final Uint8List? foto;

  Feirante({
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.cidade,
    this.foto,
  });
}