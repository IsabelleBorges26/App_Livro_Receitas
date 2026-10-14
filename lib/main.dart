
import 'package:flutter/material.dart';
import 'ui/splash.dart';
import 'ui/style/theme.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Livro de Receitas',
      theme: AppTheme.temaClaro,
      darkTheme: AppTheme.temaEscuro,
      themeMode: ThemeMode.system,
      home: const Splash(),
    ),
  );
}
