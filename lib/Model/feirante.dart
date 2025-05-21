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
  final DateTime? dataCadastro; // Certifique-se de que este campo existe

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
    this.dataCadastro, // Adicione no construtor
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
          // O Xata retorna 'xata.createdAt' em formato ISO 8601 UTC.
          // '.toLocal()' converte para a hora local do dispositivo.
          return DateTime.parse(dateTimeString).toLocal();
        } catch (e) {
          print('Erro ao parsear data: $e');
          return null;
        }
      }
      return null;
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
      dependentesQuantidade: json['dependentes_quantidade'] as int?, // Ajuste o nome do campo se necessário
      feirasSelecionadas: _convertListToSet(json['feiras']), // Ajuste o nome do campo
      produtosSelecionados: _convertListToSet(json['produtos']), // Ajuste o nome do campo
      quantidadeBancas: json['quantidade_bancas'] as int, // Ajuste o nome do campo
      localColeta: json['local_coleta'] as String, // Ajuste o nome do campo
      dataCadastro: _parseDateTime(json['xata.createdAt']), // <-- Lendo a data de criação do Xata
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Normalmente o ID não é enviado ao criar/atualizar
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
      // 'xata.createdAt': dataCadastro?.toIso8601String(), // Não envie, o Xata gera automaticamente
    };
  }
}