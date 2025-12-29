import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'main.dart';

class SemanaMaximaPage extends StatefulWidget {
  final UserRole role;
  const SemanaMaximaPage({super.key, required this.role});

  @override
  State<SemanaMaximaPage> createState() => _SemanaMaximaPageState();
}

class _SemanaMaximaPageState extends State<SemanaMaximaPage> {
  DateTime? _inicio;
  DateTime? _fim;
  bool _salvando = false;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusive(DateTime d) => DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<void> _selecionarInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inicio ?? DateTime.now(),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _inicio = picked);
  }

  Future<void> _selecionarFim() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fim ?? DateTime.now(),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fim = picked);
  }

  Future<void> _iniciarSemana() async {
    if (_inicio == null || _fim == null) return;
    if (_inicio!.isAfter(_fim!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data de início deve ser antes do encerramento.')));
      return;
    }
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance.collection('semana_maxima').doc('config').set({
        'active': true,
        'inicio': Timestamp.fromDate(_startOfDay(_inicio!)),
        'fim': Timestamp.fromDate(_startOfDay(_fim!)),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semana Máxima iniciada!')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _encerrarSemana() async {
    setState(() => _salvando = true);
    try {
      await FirebaseFirestore.instance.collection('semana_maxima').doc('config').set({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semana Máxima encerrada.')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Semana Máxima'),
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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('semana_maxima').doc('config').snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final active = (data?['active'] ?? false) as bool;
            final inicioTs = data?['inicio'] as Timestamp?;
            final fimTs = data?['fim'] as Timestamp?;
            final inicio = inicioTs?.toDate();
            final fim = fimTs?.toDate();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.role == UserRole.admin) ...[
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Controle da Semana Máxima', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selecionarInicio,
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_inicio == null ? 'Definir início' : 'Início: ${_inicio!.day.toString().padLeft(2, '0')}/${_inicio!.month.toString().padLeft(2, '0')}/${_inicio!.year}'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selecionarFim,
                                    icon: const Icon(Icons.event),
                                    label: Text(_fim == null ? 'Definir encerramento' : 'Encerramento: ${_fim!.day.toString().padLeft(2, '0')}/${_fim!.month.toString().padLeft(2, '0')}/${_fim!.year}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _salvando ? null : _iniciarSemana,
                                  icon: const Icon(Icons.play_arrow),
                                  label: _salvando ? const Text('Salvando...') : const Text('Iniciar Semana Máxima'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _salvando ? null : _encerrarSemana,
                                  icon: const Icon(Icons.stop_circle),
                                  label: const Text('Encerrar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              active
                                  ? 'Status: ATIVA' + (inicio != null && fim != null ? ' (${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year} até ${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year})' : '')
                                  : 'Status: Inativa',
                              style: TextStyle(color: active ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Ranking da Semana Máxima', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (!active || inicio == null || fim == null)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Nenhuma Semana Máxima ativa. Aguarde o início definido pelo administrador.'),
                            )
                          else
                            _RankingSemanaMaxima(inicio: inicio, fim: fim),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RankingSemanaMaxima extends StatelessWidget {
  final DateTime inicio;
  final DateTime fim;
  const _RankingSemanaMaxima({required this.inicio, required this.fim});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(inicio.year, inicio.month, inicio.day);
    final endExclusive = DateTime(fim.year, fim.month, fim.day).add(const Duration(days: 1));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('lancamentos')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(endExclusive))
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nenhum lançamento dentro do período definido.'),
          );
        }
        final docs = snapshot.data!.docs;
        final Map<String, double> ranking = {};
        final Map<String, String> nomes = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final id = (data['colportorId'] ?? 'Desconhecido').toString();
          final nome = (data['colportorNome'] ?? id).toString();
          final valor = ((data['valor'] ?? 0) as num).toDouble();
          ranking[id] = (ranking[id] ?? 0) + valor;
          nomes[id] = nome;
        }
        final rankingList = ranking.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rankingList.length,
          itemBuilder: (context, index) {
            final entry = rankingList[index];
            final nome = nomes[entry.key] ?? entry.key;
            final valor = entry.value;
            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.amber
                      : (index == 1
                          ? Colors.grey
                          : (index == 2 ? Colors.brown : Colors.blueGrey)),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  nome,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Total no período: R\$ ${valor.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.emoji_events, color: Colors.teal, size: 28),
              ),
            );
          },
        );
      },
    );
  }
}
