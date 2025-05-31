import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../Model/feirante.dart'; // Certifique-se de que este import está correto

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

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Resposta bruta: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('❌ Exceção ao criar feirante: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeirantes() async {
    final url = Uri.parse('$baseUrl/tables/feirantes/query');

    print('📤 Solicitando feirantes em: $url');

    try {
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
            'xata.createdAt',
            'xata.updatedAt', // Adicionar esta linha
          ],
        }),
      );

      print('📥 Status da busca de feirantes: ${response.statusCode}');
      print('📥 Resposta bruta da busca de feirantes: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = const Utf8Decoder().convert(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        return List<Map<String, dynamic>>.from(data['records'] ?? []);
      } else {
        print('❌ Erro HTTP ao buscar feirantes: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao buscar feirantes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exceção ao buscar feirantes (fetchFeirantes): $e');
      throw Exception('Exceção ao buscar feirantes: $e');
    }
  }


  // **NOVA IMPLEMENTAÇÃO DE getAllFeirantes (ou a que você já tem, ajustada):**
  Future<List<Feirante>> getAllFeirantes() async {
    try {
      final List<Map<String, dynamic>> feirantesData = await fetchFeirantes();
      return feirantesData.map((data) {
        // O Xata retorna a data de criação em 'xata.createdAt'.
        // O seu modelo Feirante precisa ler este campo.
        // Se o seu Feirante.fromJson já lida com 'xata.createdAt', você não precisa
        // desta lógica de renomear aqui, apenas certifique-se que 'xata.createdAt'
        // está nas colunas solicitadas em fetchFeirantes.
        return Feirante.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ Erro em getAllFeirantes: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  Future<String?> getFeiranteIdByCpf(String cpf) async {
    final url = Uri.parse('$baseUrl/tables/feirantes/query');

    print('📤 Buscando ID do feirante (CPF: $cpf) em: $url');

    try {
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
        final decodedBody = const Utf8Decoder().convert(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        if (records.isNotEmpty) {
          return records.first['id'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('❌ Exceção ao buscar ID do feirante por CPF: $e');
      return null;
    }
  }

  Future<bool> updateFeirante(String cpf, Map<String, dynamic> data) async {
    try {
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
    } catch (e) {
      print('❌ Exceção ao atualizar feirante: $e');
      return false;
    }
  }
}