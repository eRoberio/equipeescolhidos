import 'package:flutter/material.dart';
import 'package:thechosenrankin/daily_report_page.dart';
import 'goal_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'login_page.dart';

// Campo de input para simulação de venda manual
class _SimulateSaleInput extends StatefulWidget {
  final GoalController controller;
  const _SimulateSaleInput({required this.controller});

  @override
  State<_SimulateSaleInput> createState() => _SimulateSaleInputState();
}

class _SimulateSaleInputState extends State<_SimulateSaleInput> {
  final TextEditingController _valueController = TextEditingController();
  String? _error;

  void _submit() {
    final text = _valueController.text.replaceAll(',', '.');
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      setState(() => _error = 'Informe um valor válido (> 0)');
      return;
    }
    setState(() => _error = null);
    widget.controller.addSale(value);
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Simular venda (R\$)',
              errorText: _error,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Simular'),
          onPressed: _submit,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }
}


// Estado e lógica
class GoalController extends ValueNotifier<double> {
  final double goalValue;
  double _lastSale = 0.0;

  GoalController({required this.goalValue}) : super(0.0);

  double get soldValue => value;
  double get percent => (value / goalValue).clamp(0, 1);
  double get missing => (goalValue - value).clamp(0, goalValue);
  double get lastSale => _lastSale;

  void addSale(double sale) {
    _lastSale = sale;
    value += sale;
  }

  bool get goalReached => value >= goalValue;
}

// UI principal


class GoalDashboardPage extends StatelessWidget {
  final String userId;
  final UserRole role;
  const GoalDashboardPage({super.key, required this.userId, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Painel de Meta de Vendas'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => MyApp.requestLogout(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF0E2A26), Color(0xFF1B5E57)]
                : const [Colors.white, Color(0xFFEFF7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('campanhas')
                    .orderBy('criadaEm', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, campanhaSnap) {
                  if (campanhaSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (campanhaSnap.hasError) {
                    return Center(child: Text('Erro ao carregar campanha: ${campanhaSnap.error}'));
                  }
                  final campanha = campanhaSnap.data?.docs.isNotEmpty == true ? campanhaSnap.data!.docs.first : null;
                  if (campanha == null) {
                    return const Center(child: Text('Nenhuma campanha ativa. Crie uma no menu.'));
                  }
                  final double goalValue = (campanha['meta'] as num?)?.toDouble() ?? 0.0;
                  final Timestamp? dataFinalTs = campanha['dataFinal'] as Timestamp?;
                  final DateTime? dataFinal = dataFinalTs?.toDate();

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lancamentos')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final vendas = docs
                          .map((doc) => (doc['valor'] as num?)?.toDouble() ?? 0.0)
                          .toList();
                      final totalVendido = vendas.fold<double>(0.0, (a, b) => a + b);
                      final percent = (totalVendido / goalValue).clamp(0, 1);
                      final missing = (goalValue - totalVendido).clamp(0, goalValue);
                      final goalReached = totalVendido >= goalValue;
                      final lastSale = vendas.isNotEmpty ? vendas.first : 0.0;

                      return _PainelLayout(
                        goalValue: goalValue,
                        totalVendido: totalVendido,
                        percent: percent.toDouble(),
                        missing: missing.toDouble(),
                        goalReached: goalReached,
                        lastSale: lastSale,
                        dataFinal: dataFinal,
                        userId: userId,
                        role: role,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelLayout extends StatefulWidget {
  final double goalValue, totalVendido, percent, missing, lastSale;
  final bool goalReached;
  final DateTime? dataFinal;
  final String userId;
  final UserRole role;
  const _PainelLayout({
    required this.goalValue,
    required this.totalVendido,
    required this.percent,
    required this.missing,
    required this.goalReached,
    required this.lastSale,
    required this.dataFinal,
    required this.userId,
    required this.role,
  });

  @override
  State<_PainelLayout> createState() => _PainelLayoutState();
}

class _PainelLayoutState extends State<_PainelLayout> {
  late Duration _restante;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRestante();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRestante());
  }

  void _updateRestante() {
    setState(() {
      if (widget.dataFinal != null) {
        _restante = widget.dataFinal!.difference(DateTime.now());
      } else {
        _restante = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dias = _restante.inDays;
    final horas = _restante.inHours % 24;
    final minutos = _restante.inMinutes % 60;
    final segundos = _restante.inSeconds % 60;
    final tempoAcabou = _restante.isNegative;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GoalHeader(goalValue: widget.goalValue),
          const SizedBox(height: 16),
          if (widget.dataFinal != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: tempoAcabou
                    ? const Text(
                        '⏰ Tempo esgotado!',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CronoBox(label: 'Dias', value: dias),
                          _CronoBox(label: 'Horas', value: horas),
                          _CronoBox(label: 'Min', value: minutos),
                          _CronoBox(label: 'Seg', value: segundos),
                        ],
                      ),
              ),
            ),
          SoldValueDisplay(
            soldValue: widget.totalVendido,
            onGoalReached: widget.goalReached,
          ),
          const SizedBox(height: 16),
          GoalProgressBar(percent: widget.percent),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.goalReached
                  ? 'Meta atingida!'
                    : 'Falta ${NumberFormat.simpleCurrency(locale: 'pt_BR').format(widget.missing)}',
                style: TextStyle(
                    fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: widget.goalReached
                      ? Colors.amber
                      : Theme.of(context).colorScheme.error,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          MotivationalText(
            missing: widget.missing,
            percent: widget.percent,
            goalReached: widget.goalReached,
          ),
          const SizedBox(height: 16),
          if (widget.lastSale > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Último valor lançado:',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      NumberFormat.simpleCurrency(locale: 'pt_BR').format(widget.lastSale),
                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // COLPORTOR lança para si, ADMIN para qualquer colportor
          if (widget.role == UserRole.colportor || widget.role == UserRole.admin)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assignment),
                label: const Text('Relatório Diário'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyReportPage(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}


class _CronoBox extends StatelessWidget {
  final String label;
  final int value;
  const _CronoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
