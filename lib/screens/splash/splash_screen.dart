import 'package:flutter/material.dart';
import '../../widgets/app_logo.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Duração total da animação aumentada para dar tempo de ver tudo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // 1. Animação de Escala do Logo (ocorre entre 0% e 50% do tempo)
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // 2. Animação de Opacidade do Logo (ocorre entre 0% e 40% do tempo)
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 3. Animação de Opacidade do Texto (Só começa quando o logo está quase pronto: 50% a 90%)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navegação após a conclusão total
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_love.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Grupo do Logo
                Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: const AppLogo(size: 360),
                  ),
                ),

                const SizedBox(height: 30),

                // Grupo de Texto (Aparece em fade-in depois)
                Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: const [
                      Text(
                        "Seja bem vindo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Conecte-se com pessoas\nsem tabus e sem limites.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18, // Ajustado para melhor leitura
                          height: 1.5, // Espaçamento entre linhas
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
