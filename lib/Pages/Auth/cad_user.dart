import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../Model/agente.dart';
import '../../services/agente_service.dart';
import '../cadastro feirantes/feirante_cadastro.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _funcaoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirmaSenha = true;

  final AgenteService _agenteService = AgenteService();

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _funcaoController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  void _toggleSenhaVisibility() {
    setState(() {
      _obscureSenha = !_obscureSenha;
    });
  }

  void _toggleConfirmaSenhaVisibility() {
    setState(() {
      _obscureConfirmaSenha = !_obscureConfirmaSenha;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final senha = _senhaController.text;
      final senhaHash = sha256.convert(utf8.encode(senha)).toString();

      final agente = Agente(
        nome: _nomeController.text.trim(),
        matricula: int.parse(_matriculaController.text.trim()),
        funcao: _funcaoController.text.trim(),
        senhaHash: senhaHash,
        ativo: true,
        criadoEm: DateTime.now(),
      );

      final sucesso = await _agenteService.createAgente(agente.toJson());

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro bem-sucedido!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeiranteCadastroScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar o agente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.store,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CADASTRO DE FEIRANTES',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Por favor, insira seu nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _matriculaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Matrícula',
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua matrícula';
                        }
                        if (int.tryParse(value) == null) {
                          return 'A matrícula deve ser um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _funcaoController,
                      decoration: InputDecoration(
                        labelText: 'Função',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Por favor, insira sua função' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _obscureSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSenha ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: _toggleSenhaVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmaSenhaController,
                      obscureText: _obscureConfirmaSenha,
                      decoration: InputDecoration(
                        labelText: 'Confirma Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmaSenha ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: _toggleConfirmaSenhaVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme sua senha';
                        }
                        if (value != _senhaController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cadastrar'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
