import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AgenteService {
  final String baseUrl = 'https://handerson-lima-s-workspace-m90ec2.us-east-1.xata.sh/db/cadfeiras:main';
  final String apiKey = 'xau_HgOdvovP03Vs9vX3hTtycn86G2pV44T75'; // ✅ Corrigido

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  Future<http.Response> createRecord(String table, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/tables/$table/data');
    print('🔄 Enviando POST para: $url');
    print('📦 Payload: ${jsonEncode(data)}');

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(data),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');
    return response;
  }

  Future<http.Response> getRecordById(String table, String id) async {
    final url = Uri.parse('$baseUrl/tables/$table/data/$id');
    print('🔍 GET $url');

    final response = await http.get(url, headers: _headers);

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');
    return response;
  }

  Future<http.Response> updateRecord(String table, String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/tables/$table/data/$id');
    print('✏️ PUT $url');
    print('📦 Payload: ${jsonEncode(data)}');

    final response = await http.put(
      url,
      headers: _headers,
      body: jsonEncode(data),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');
    return response;
  }

  Future<http.Response> deleteRecord(String table, String id) async {
    final url = Uri.parse('$baseUrl/tables/$table/data/$id');
    print('🗑️ DELETE $url');

    final response = await http.delete(url, headers: _headers);

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');
    return response;
  }

  Future<Map<String, dynamic>?> loginAgente(String matricula, String senha) async {
    final queryUrl = '$baseUrl/tables/agentes/query';
    print('🔐 Tentando login com matrícula: $matricula');

    final body = {
      "filter": {
        "matricula": int.tryParse(matricula) ?? 0  // ✅ Filtro direto, sem operadores
      },
      "columns": ["id", "nome", "matricula", "funcao", "senha_hash", "ativo"]
    };

    final response = await http.post(
      Uri.parse(queryUrl),
      headers: _headers,
      body: jsonEncode(body),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['records'] != null && decoded['records'].isNotEmpty) {
        final agente = decoded['records'][0];

        final senhaHash = sha256.convert(utf8.encode(senha)).toString();

        if (agente['senha_hash'] == senhaHash && agente['ativo'] == true) {
          print('✅ Login bem-sucedido para ${agente['nome']}');
          return agente;
        } else {
          print('❌ Senha inválida ou usuário inativo');
        }
      } else {
        print('❌ Nenhum agente encontrado com a matrícula fornecida');
      }
    } else {
      print('❌ Erro na requisição de login: ${response.statusCode}');
    }

    return null;
  }



  Future<bool> createAgente(Map<String, dynamic> data) async {
    try {
      // 🔒 Remove campos inválidos antes de enviar
      final cleanData = {
        "nome": data['nome'],
        "matricula": data['matricula'],
        "funcao": data['funcao'],
        "senha_hash": data['senha_hash'],
        "ativo": data['ativo'] ?? true,
      };

      final response = await createRecord('agentes', cleanData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Agente cadastrado com sucesso');
        return true;
      } else {
        print('❌ Falha ao cadastrar agente (Status: ${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('💥 Erro ao criar agente: $e');
      return false;
    }
  }
}
