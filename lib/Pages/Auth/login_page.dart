import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../homepage/homepage.dart';
import 'cad_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _matriculaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://cadfeiras.h2solucoes.top/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'matricula': _matriculaController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Aqui você pode salvar o token JWT (por exemplo, usando shared_preferences)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login bem-sucedido! Bem-vindo, ${_matriculaController.text}')),
          );
          // Navegar para a homepage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          final error = jsonDecode(response.body)['message'] ?? 'Erro ao fazer login';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão com o servidor')),
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
              // Logomarca
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
              // Título
              const Text(
                'CADASTRO DE FEIRANTES',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              // Formulário
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo de matrícula
                    TextFormField(
                      controller: _matriculaController,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo de senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: _togglePasswordVisibility,
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
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Botão Entrar
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 16),
              // Botão Cadastre-se
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CadastroScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Cadastre-se',
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