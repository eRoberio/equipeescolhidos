import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Gráficos'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _PieCard(
              title: "Ranking de Vendas (R\$)",
              collection: 'lancamentos',
              valueField: 'valor',
              isCurrency: true,
            ),
            SizedBox(height: 16),
            _PieCard(
              title: 'Ranking Geral (Pontos)',
              collection: 'pontos_gerais',
              valueField: 'pontos',
              isCurrency: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final String collection;
  final String valueField;
  final bool isCurrency;
  const _PieCard({
    required this.title,
    required this.collection,
    required this.valueField,
    required this.isCurrency,
  });

  static const _palette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFFD81B60),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF00ACC1),
    Color(0xFF7CB342),
    Color(0xFFF4511E),
    Color(0xFF5E35B1),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection(collection).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }
                final docs = snapshot.data!.docs;
                final Map<String, double> totals = {};
                final Map<String, String> names = {};
                for (final doc in docs) {
                  final id = (doc['colportorId'] ?? 'Desconhecido').toString();
                  final nome = (doc['colportorNome'] ?? id).toString();
                  final raw = doc[valueField];
                  double v = 0;
                  if (raw is num) v = raw.toDouble();
                  totals[id] = (totals[id] ?? 0) + v;
                  names[id] = nome;
                }
                if (totals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }
                final entries = totals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final totalSum = entries.fold<double>(0, (p, e) => p + e.value);
                final sections = <PieChartSectionData>[];
                for (var i = 0; i < entries.length; i++) {
                  final e = entries[i];
                  final pct = totalSum == 0 ? 0 : (e.value / totalSum) * 100;
                  sections.add(
                    PieChartSectionData(
                      value: e.value,
                      color: _palette[i % _palette.length],
                      title: '${pct.toStringAsFixed(1)}%',
                      radius: 70,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          _LegendItem(
                            color: _palette[i % _palette.length],
                            label: names[entries[i].key] ?? entries[i].key,
                            value: entries[i].value,
                            isCurrency: isCurrency,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final bool isCurrency;
  const _LegendItem({super.key, required this.color, required this.label, required this.value, required this.isCurrency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(
            isCurrency ? 'R\$ ${value.toStringAsFixed(2)}' : value.toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
