import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
// Widget: Barra de progresso animada
class GoalProgressBar extends StatelessWidget {
  final double percent;
  const GoalProgressBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, _) {
        return LinearProgressIndicator(
          value: value,
          minHeight: 12,
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }
}

// Widget: Texto motivacional
class MotivationalText extends StatelessWidget {
    String get _brl => NumberFormat.simpleCurrency(locale: 'pt_BR').format(missing);
  final double missing;
  final double percent;
  final bool goalReached;
  const MotivationalText({
    super.key,
    required this.missing,
    required this.percent,
    required this.goalReached,
  });

  @override
  Widget build(BuildContext context) {
    if (goalReached) {
      return const Text(
        '🏆 Parabéns! Meta atingida!',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '🔥 Falta só $_brl para bater a meta!',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '🚀 ${NumberFormat.decimalPattern('pt_BR').format(percent * 100)}% da meta atingida',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// Widget: Meta
class GoalHeader extends StatelessWidget {
    String get _brl => NumberFormat.simpleCurrency(locale: 'pt_BR').format(goalValue);
  final double goalValue;
  const GoalHeader({super.key, required this.goalValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Image.asset(
            'assets/thechosen2.png',
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
        const Text('🎯 Meta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _brl,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 48,
                    ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class SoldValueDisplay extends StatefulWidget {
  final double soldValue;
  final bool onGoalReached;
  const SoldValueDisplay({super.key, required this.soldValue, required this.onGoalReached});

  @override
  State<SoldValueDisplay> createState() => _SoldValueDisplayState();
}

class _SoldValueDisplayState extends State<SoldValueDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  double _oldValue = 0;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant SoldValueDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.soldValue > _oldValue) {
      _controller.forward(from: 0);
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }
    _oldValue = widget.soldValue;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_showConfetti)
          Lottie.asset('assets/confetti.json', width: 320, repeat: false),
        if (widget.onGoalReached)
          Lottie.asset('assets/trophy.json', repeat: false, width: 180),
        ScaleTransition(
          scale: _scale,
          child: Column(
            children: [
              const Text('💰 Vendido até agora', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              Text(
                NumberFormat.simpleCurrency(locale: 'pt_BR').format(widget.soldValue),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 52,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
