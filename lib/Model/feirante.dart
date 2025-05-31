// lib/Model/feirante.dart

import 'dart:typed_data';
import 'dart:convert'; // Para base64

class Feirante {
  String? id;
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
  final DateTime? dataCadastro;
  final DateTime? dataAtualizacao; // Novo campo

  Feirante({
    this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.cidade,
    this.foto,
    required this.endereco,
    this.complemento,
    this.dependentesQuantidade,
    required this.feirasSelecionadas,
    required this.produtosSelecionados,
    required this.quantidadeBancas,
    required this.localColeta,
    this.dataCadastro,
    this.dataAtualizacao, // Adicionado ao construtor
  });

  factory Feirante.fromJson(Map<String, dynamic> json) {
    Set<String> _convertListToSet(dynamic list) {
      if (list is List) {
        return Set<String>.from(list.map((e) => e.toString()));
      }
      return {};
    }

    Uint8List? _decodeBase64Image(dynamic base64String) {
      if (base64String is String && base64String.isNotEmpty) {
        try {
          return base64Decode(base64String);
        } catch (e) {
          print('Erro ao decodificar base64 da imagem: $e');
          return null;
        }
      }
      return null;
    }

    DateTime? _parseDateTime(dynamic dateTimeString) {
      if (dateTimeString is String && dateTimeString.isNotEmpty) {
        try {
          return DateTime.parse(dateTimeString).toLocal();
        } catch (e) {
          print('Erro ao parsear data em Feirante.fromJson: $e. String recebida: "$dateTimeString"');
          return null;
        }
      }
      return null;
    }

    String? createdAtString;
    String? updatedAtString; // Variável para updatedAt

    if (json['xata'] != null && json['xata'] is Map<String, dynamic>) {
      createdAtString = json['xata']['createdAt'] as String?;
      updatedAtString = json['xata']['updatedAt'] as String?; // Extrair updatedAt
    } else {
      print("WARN: Estrutura json['xata'] não encontrada ou não é um mapa no registro com id: ${json['id']}");
    }

    return Feirante(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      cpf: json['cpf'] as String,
      telefone: json['telefone'] as String,
      cidade: json['cidade'] as String,
      foto: _decodeBase64Image(json['foto']),
      endereco: json['endereco'] as String,
      complemento: json['complemento'] as String?,
      dependentesQuantidade: json['dependentes_quantidade'] as int?,
      feirasSelecionadas: _convertListToSet(json['feiras']),
      produtosSelecionados: _convertListToSet(json['produtos']),
      quantidadeBancas: (json['quantidade_bancas'] as num?)?.toInt() ?? 0,
      localColeta: json['local_coleta'] as String? ?? '',
      dataCadastro: _parseDateTime(createdAtString),
      dataAtualizacao: _parseDateTime(updatedAtString), // Passar para o construtor
    );
  }

  Map<String, dynamic> toJson() {
    // O toJson não precisa incluir dataCadastro ou dataAtualizacao,
    // pois são campos gerenciados pelo Xata (xata.createdAt, xata.updatedAt)
    return {
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'cidade': cidade,
      'foto': foto != null ? base64Encode(foto!) : null,
      'endereco': endereco,
      'complemento': complemento,
      'dependentes_quantidade': dependentesQuantidade,
      'feiras': feirasSelecionadas.toList(),
      'produtos': produtosSelecionados.toList(),
      'quantidade_bancas': quantidadeBancas,
      'local_coleta': localColeta,
    };
  }
}