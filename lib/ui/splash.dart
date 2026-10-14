
import 'package:flutter/material.dart';
import 'home.dart';
import 'style/colors.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animacao;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animacao = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    controller.forward().then((_) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Home(),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.c5,
      body: Center(
        child: ScaleTransition(
          scale: animacao,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icone.png',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 20),
              Text(
                'Livro de Receitas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Receitas para todos os momentos'),
            ],
          ),
        ),
      ),
    );
  }
}
