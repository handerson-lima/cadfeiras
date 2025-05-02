
class Agente {
  final String? id;
  final String nome;
  final int matricula;
  final String funcao;
  final String senhaHash;
  final bool ativo;
  final DateTime? criadoEm;

  Agente({
    this.id,
    required this.nome,
    required this.matricula,
    required this.funcao,
    required this.senhaHash,
    required this.ativo,
    this.criadoEm,
  });

  factory Agente.fromJson(Map<String, dynamic> json) {
    return Agente(
      id: json['id'],
      nome: json['nome'],
      matricula: json['matricula'],
      funcao: json['funcao'],
      senhaHash: json['senha_hash'],
      ativo: json['ativo'] ?? false,
      criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'matricula': matricula,
      'funcao': funcao,
      'senha_hash': senhaHash,
      'ativo': ativo,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
