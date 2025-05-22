import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import necessário
import 'Pages/Auth/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Feirantes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // --- Configurações de Localização para pt-BR ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português do Brasil
        // Adicione outros idiomas que você planeja suportar no futuro
      ],
      locale: const Locale('pt', 'BR'), // Força o idioma para Português do Brasil
      // --- Fim das Configurações de Localização ---
      home: const LoginScreen(), // O nome da sua classe de login é LoginPage
    );
  }
}

