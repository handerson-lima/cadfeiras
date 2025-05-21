import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _agenteCount = 0;
  int? _feiranteCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('[DashboardScreen] initState chamado às ${DateTime.now()}');
    _fetchCounts();
    _logAccess();
  }

  Future<void> _fetchCounts() async {
    print('[DashboardScreen] Iniciando _fetchCounts');
    setState(() {
      _isLoading = true;
    });

    try {
      print('[DashboardScreen] Fazendo requisição para contagem da tabela agentes');
      final agenteResponse = await http.post(
        Uri.parse('https://handerson-lima-s-workspace-m90ec2.us-east-1.xata.sh/db/cadfeiras:main/tables/agentes/summarize'),
        headers: {
          'Authorization': 'Bearer xau_lfYNfcPIanNaDW2YEbn3MQ5OQ1eTntDI',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "summaries": {
            "totalCount": {
              "count": "*"
            }
          }
        }),
      );

      print('[DashboardScreen] Resposta recebida para agentes: ${agenteResponse.statusCode}');
      print('[DashboardScreen] Corpo da resposta (agentes): ${agenteResponse.body}');

      print('[DashboardScreen] Fazendo requisição para contagem da tabela feirantes');
      final feiranteResponse = await http.post(
        Uri.parse('https://handerson-lima-s-workspace-m90ec2.us-east-1.xata.sh/db/cadfeiras:main/tables/feirantes/summarize'),
        headers: {
          'Authorization': 'Bearer xau_lfYNfcPIanNaDW2YEbn3MQ5OQ1eTntDI',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "summaries": {
            "totalCount": {
              "count": "*"
            }
          }
        }),
      );

      print('[DashboardScreen] Resposta recebida para feirantes: ${feiranteResponse.statusCode}');
      print('[DashboardScreen] Corpo da resposta (feirantes): ${feiranteResponse.body}');

      if (agenteResponse.statusCode == 200 && feiranteResponse.statusCode == 200) {
        final agenteData = jsonDecode(agenteResponse.body);
        final feiranteData = jsonDecode(feiranteResponse.body);

        print('[DashboardScreen] JSON completo de agentes: $agenteData');
        print('[DashboardScreen] JSON completo de feirantes: $feiranteData');

        setState(() {
          // MODIFICAÇÃO AQUI: Acesse o primeiro elemento da lista 'summaries'
          _agenteCount = (agenteData['summaries'] != null && agenteData['summaries'].isNotEmpty)
              ? agenteData['summaries'][0]['totalCount'] ?? 0
              : 0;
          _feiranteCount = (feiranteData['summaries'] != null && feiranteData['summaries'].isNotEmpty)
              ? feiranteData['summaries'][0]['totalCount'] ?? 0
              : 0;
          _isLoading = false;
          print('[DashboardScreen] Contagens atualizadas: agentes=$_agenteCount, feirantes=$_feiranteCount');
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final errorMessageAgente = agenteResponse.statusCode != 200
            ? jsonDecode(agenteResponse.body)['message'] ?? 'Erro desconhecido'
            : '';
        final errorMessageFeirante = feiranteResponse.statusCode != 200
            ? jsonDecode(feiranteResponse.body)['message'] ?? 'Erro desconhecido'
            : '';
        final fullErrorMessage = (errorMessageAgente.isNotEmpty ? 'Agentes: $errorMessageAgente; ' : '') +
            (errorMessageFeirante.isNotEmpty ? 'Feirantes: $errorMessageFeirante' : '');

        print('[DashboardScreen] Erro ao carregar os dados: $fullErrorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar os dados: $fullErrorMessage')),
        );
        _logError('Erro ao carregar contagens', fullErrorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('[DashboardScreen] Erro de conexão com o servidor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão com o servidor: $e')),
      );
      _logError('Erro de conexão', e.toString());
    }
  }

  Future<void> _logAccess() async {
    print('[DashboardScreen] Registrando acesso ao dashboard');
    await LogService.log('Dashboard Access', 'Usuário acessou o dashboard às ${DateTime.now().toIso8601String()}');
  }

  Future<void> _logError(String action, String details) async {
    print('[DashboardScreen] Registrando erro: $action - $details');
    await LogService.log(action, details);
  }

  @override
  Widget build(BuildContext context) {
    print('[DashboardScreen] Construindo interface do dashboard');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Informações Gerais',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Agentes Cadastrados'),
                subtitle: Text('Total: ${_agenteCount ?? 0}'),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.store, color: Colors.green),
                title: const Text('Feirantes Cadastrados'),
                subtitle: Text('Total: ${_feiranteCount ?? 0}'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('[DashboardScreen] Botão Sair pressionado');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class LogService {
  static const String _apiKey = 'xau_lfYNfcPIanNaDW2YEbn3MQ5OQ1eTntDI';
  static const String _baseUrl = 'https://handerson-lima-s-workspace-m90ec2.us-east-1.xata.sh/db/cadfeiras:main/tables/logs/data';

  static Future<void> log(String action, String details) async {
    print('[LogService] Iniciando registro de log: $action - $details');
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // ALTERE ESTA LINHA:
          'timestamp': DateTime.now().toUtc().toIso8601String(), // Adicione .toUtc()
          'action': action,
          'details': details,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) { // Adicione a verificação para 201
        print('[LogService] Erro ao registrar log: ${response.statusCode} - ${response.body}');
      } else {
        print('[LogService] Log registrado com sucesso');
      }
    } catch (e) {
      print('[LogService] Erro ao enviar log ao servidor: $e');
    }
  }
}
