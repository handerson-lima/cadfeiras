import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FeiranteService {
  final String baseUrl = 'https://handerson-lima-s-workspace-m90ec2.us-east-1.xata.sh/db/cadfeiras:main';
  final String apiKey = 'xau_HgOdvovP03Vs9vX3hTtycn86G2pV44T75';

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  Future<bool> createFeirante(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/tables/feirantes/data');

    print('📤 Enviando cadastro de feirante: ${jsonEncode(data)}');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta bruta: ${response.body}');

    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> fetchFeirantes() async {
    final url = Uri.parse('$baseUrl/tables/feirantes/query');

    print('📤 Solicitando feirantes em: $url');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'columns': [
          'id',
          'cpf',
          'nome',
          'telefone',
          'cidade',
          'foto',
          'endereco',
          'complemento',
          'dependentes_quantidade',
          'feiras',
          'produtos',
          'quantidade_bancas',
          'local_coleta',
        ],
      }),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta bruta: ${response.body}');

    if (response.statusCode == 200) {
      // Decodificar manualmente como UTF-8
      final decodedBody = const Utf8Decoder().convert(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      return List<Map<String, dynamic>>.from(data['records'] ?? []);
    } else {
      throw Exception('Erro ao buscar feirantes: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String?> getFeiranteIdByCpf(String cpf) async {
    final url = Uri.parse('$baseUrl/tables/feirantes/query');

    print('📤 Buscando ID do feirante (CPF: $cpf) em: $url');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'filter': {'cpf': cpf},
        'columns': ['id'],
      }),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta bruta: ${response.body}');

    if (response.statusCode == 200) {
      // Decodificar manualmente como UTF-8
      final decodedBody = const Utf8Decoder().convert(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
      if (records.isNotEmpty) {
        return records.first['id'] as String?;
      }
    }
    return null;
  }

  Future<bool> updateFeirante(String cpf, Map<String, dynamic> data) async {
    final feiranteId = await getFeiranteIdByCpf(cpf);
    if (feiranteId == null) {
      print('📥 Erro: Feirante com CPF $cpf não encontrado.');
      throw Exception('Feirante com CPF $cpf não encontrado.');
    }

    final url = Uri.parse('$baseUrl/tables/feirantes/data/$feiranteId');

    print('📤 Atualizando feirante (ID: $feiranteId, CPF: $cpf): ${jsonEncode(data)}');

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta bruta: ${response.body}');

    return response.statusCode == 200;
  }

  getAllFeirantes() {}
}