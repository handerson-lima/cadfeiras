import 'package:flutter/material.dart';
import '../../services/agente_service.dart';
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

  final AgenteService _agenteService = AgenteService();

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
        final matricula = _matriculaController.text.trim();
        final senha = _passwordController.text.trim();

        final agente = await _agenteService.loginAgente(matricula, senha);

        setState(() {
          _isLoading = false;
        });

        if (agente != null) {
          final nome = agente['nome'] ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Bem-vindo, $nome!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Matrícula ou senha incorretos.')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Erro ao tentar login. Tente novamente.')),
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
                          return 'A matrícula deve ser numérica';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
