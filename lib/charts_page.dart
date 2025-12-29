import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  DateTime? _inicio;
  DateTime? _fim;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusive(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<void> _pickInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inicio ?? DateTime.now(),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _inicio = picked);
  }

  Future<void> _pickFim() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fim ?? (_inicio ?? DateTime.now()),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fim = picked);
  }

  @override
  Widget build(BuildContext context) {
    final inicio = _inicio != null ? _startOfDay(_inicio!) : null;
    final fim = _fim != null ? _endExclusive(_fim!) : null;
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
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF0E2A26), Color(0xFF1B5E57)]
                    : const [Colors.white, Color(0xFFEFF7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.filter_alt),
                    Text(
                      'Período',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickInicio,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _inicio == null
                            ? 'Início'
                            : DateFormat('dd/MM/yy').format(_inicio!),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFim,
                      icon: const Icon(Icons.event),
                      label: Text(
                        _fim == null
                            ? 'Fim'
                            : DateFormat('dd/MM/yy').format(_fim!),
                      ),
                    ),
                    if (_inicio != null || _fim != null)
                      TextButton.icon(
                        onPressed:
                            () => setState(() {
                              _inicio = null;
                              _fim = null;
                            }),
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpar'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PieCard(
              title: "Ranking de Vendas (R\$)",
              collection: 'lancamentos',
              valueField: 'valor',
              isCurrency: true,
              inicio: inicio,
              fim: fim,
              dateField: 'timestamp',
            ),
            const SizedBox(height: 16),
            _PieCard(
              title: 'Ranking Geral (Pontos)',
              collection: 'pontos_gerais',
              valueField: 'pontos',
              isCurrency: false,
              inicio: inicio,
              fim: fim,
              dateField: 'timestamp',
            ),
            const SizedBox(height: 16),
            _BarVendasPorColportorCard(topN: 8, inicio: inicio, fim: fim),
            const SizedBox(height: 16),
            _BarOfertasPorColportorCard(
              topN: 8,
              inicio: _inicio != null ? _startOfDay(_inicio!) : null,
              fim: _fim != null ? _endExclusive(_fim!) : null,
            ),
            const SizedBox(height: 16),
            _BarHorasPorColportorCard(
              topN: 8,
              inicio: _inicio != null ? _startOfDay(_inicio!) : null,
              fim: _fim != null ? _endExclusive(_fim!) : null,
            ),
            const SizedBox(height: 16),
            _LineVendasUltimosDiasCard(dias: 14, inicio: inicio, fim: fim),
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
  final DateTime? inicio;
  final DateTime? fim;
  final String dateField;
  const _PieCard({
    required this.title,
    required this.collection,
    required this.valueField,
    required this.isCurrency,
    this.inicio,
    this.fim,
    this.dateField = 'timestamp',
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
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: () {
                Query q = FirebaseFirestore.instance.collection(collection);
                if (inicio != null) {
                  q = q.where(
                    dateField,
                    isGreaterThanOrEqualTo: Timestamp.fromDate(inicio!),
                  );
                }
                if (fim != null) {
                  q = q.where(dateField, isLessThan: Timestamp.fromDate(fim!));
                }
                return q.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
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
                final entries =
                    totals.entries.toList()
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
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
  const _LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.isCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            isCurrency
                ? 'R\$ ${value.toStringAsFixed(2)}'
                : value.toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BarHorasPorColportorCard extends StatelessWidget {
  final int topN;
  final DateTime? inicio;
  final DateTime? fim;
  const _BarHorasPorColportorCard({
    super.key,
    this.topN = 8,
    this.inicio,
    this.fim,
  });

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
            Text(
              'Top $topN Horas por Colportor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: () {
                Query q = FirebaseFirestore.instance.collection(
                  'relatorios_diarios',
                );
                if (inicio != null) {
                  q = q.where(
                    'data',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(inicio!),
                  );
                }
                if (fim != null) {
                  q = q.where('data', isLessThan: Timestamp.fromDate(fim!));
                }
                return q.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
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
                  final data = doc.data() as Map<String, dynamic>;
                  final id = (data['colportorId'] ?? 'Desconhecido').toString();
                  final nome = (data['colportorNome'] ?? id).toString();
                  final horas = ((data['horas'] ?? 0) as num).toDouble();
                  totals[id] = (totals[id] ?? 0) + horas;
                  names[id] = nome;
                }
                var entries =
                    totals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                if (entries.length > topN)
                  entries = entries.take(topN).toList();
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }
                final maxY = entries
                    .map((e) => e.value)
                    .fold<double>(0, (p, v) => v > p ? v : p);
                return SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: maxY > 0 ? maxY / 4 : 1,
                            getTitlesWidget:
                                (v, meta) => Text(
                                  v.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= entries.length)
                                return const SizedBox.shrink();
                              final name =
                                  names[entries[idx].key] ?? entries[idx].key;
                              final short =
                                  name.length > 8
                                      ? '${name.substring(0, 8)}…'
                                      : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  short,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < entries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: entries[i].value,
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BarVendasPorColportorCard extends StatelessWidget {
  final int topN;
  final DateTime? inicio;
  final DateTime? fim;
  const _BarVendasPorColportorCard({
    super.key,
    this.topN = 8,
    this.inicio,
    this.fim,
  });

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
            Text(
              'Top $topN Vendas por Colportor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: () {
                Query q = FirebaseFirestore.instance.collection('lancamentos');
                if (inicio != null) {
                  q = q.where(
                    'timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(inicio!),
                  );
                }
                if (fim != null) {
                  q = q.where(
                    'timestamp',
                    isLessThan: Timestamp.fromDate(fim!),
                  );
                }
                return q.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
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
                  final data = doc.data() as Map<String, dynamic>;
                  final id = (data['colportorId'] ?? 'Desconhecido').toString();
                  final nome = (data['colportorNome'] ?? id).toString();
                  final valor = ((data['valor'] ?? 0) as num).toDouble();
                  totals[id] = (totals[id] ?? 0) + valor;
                  names[id] = nome;
                }
                var entries =
                    totals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                if (entries.length > topN)
                  entries = entries.take(topN).toList();

                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }

                final maxY = entries
                    .map((e) => e.value)
                    .fold<double>(0, (p, v) => v > p ? v : p);
                return SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: maxY > 0 ? maxY / 4 : 1,
                            getTitlesWidget:
                                (v, meta) => Text(
                                  'R\$ ${v.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= entries.length)
                                return const SizedBox.shrink();
                              final name =
                                  names[entries[idx].key] ?? entries[idx].key;
                              final short =
                                  name.length > 8
                                      ? '${name.substring(0, 8)}…'
                                      : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  short,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < entries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: entries[i].value,
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BarOfertasPorColportorCard extends StatelessWidget {
  final int topN;
  final DateTime? inicio;
  final DateTime? fim;
  const _BarOfertasPorColportorCard({
    super.key,
    this.topN = 8,
    this.inicio,
    this.fim,
  });

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
            Text(
              'Top $topN Ofertas por Colportor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: () {
                Query q = FirebaseFirestore.instance.collection(
                  'relatorios_diarios',
                );
                if (inicio != null) {
                  q = q.where(
                    'data',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(inicio!),
                  );
                }
                if (fim != null) {
                  q = q.where('data', isLessThan: Timestamp.fromDate(fim!));
                }
                return q.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }
                final docs = snapshot.data!.docs;
                final Map<String, int> totals = {};
                final Map<String, String> names = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = (data['colportorId'] ?? 'Desconhecido').toString();
                  final nome = (data['colportorNome'] ?? id).toString();
                  final ofertas = (data['ofertas'] ?? 0) as int;
                  totals[id] = (totals[id] ?? 0) + ofertas;
                  names[id] = nome;
                }
                var entries =
                    totals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                if (entries.length > topN)
                  entries = entries.take(topN).toList();

                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados para exibir.')),
                  );
                }

                final maxY = entries
                    .map((e) => e.value.toDouble())
                    .fold<double>(0, (p, v) => v > p ? v : p);
                return SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval:
                            maxY > 0 ? (maxY / 4).clamp(1, double.infinity) : 1,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval:
                                maxY > 0
                                    ? (maxY / 4).clamp(1, double.infinity)
                                    : 1,
                            getTitlesWidget:
                                (v, meta) => Text(
                                  v.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= entries.length)
                                return const SizedBox.shrink();
                              final name =
                                  names[entries[idx].key] ?? entries[idx].key;
                              final short =
                                  name.length > 8
                                      ? '${name.substring(0, 8)}…'
                                      : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  short,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < entries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: entries[i].value.toDouble(),
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LineVendasUltimosDiasCard extends StatelessWidget {
  final int dias;
  final DateTime? inicio;
  final DateTime? fim;
  const _LineVendasUltimosDiasCard({
    super.key,
    this.dias = 14,
    this.inicio,
    this.fim,
  });

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
            Text(
              'Vendas por Dia (últimos $dias)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<QuerySnapshot>(
              future: () async {
                DateTime start;
                DateTime endExcl;
                if (inicio != null && fim != null) {
                  start = DateTime(inicio!.year, inicio!.month, inicio!.day);
                  endExcl = DateTime(
                    fim!.year,
                    fim!.month,
                    fim!.day,
                  ).add(const Duration(days: 1));
                } else {
                  final now = DateTime.now();
                  start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: dias - 1));
                  endExcl = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).add(const Duration(days: 1));
                }
                Query q = FirebaseFirestore.instance
                    .collection('lancamentos')
                    .where(
                      'timestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                    )
                    .where(
                      'timestamp',
                      isLessThan: Timestamp.fromDate(endExcl),
                    );
                return q.get();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Sem dados.')),
                  );
                }
                DateTime start;
                DateTime endExcl;
                if (inicio != null && fim != null) {
                  start = DateTime(inicio!.year, inicio!.month, inicio!.day);
                  endExcl = DateTime(
                    fim!.year,
                    fim!.month,
                    fim!.day,
                  ).add(const Duration(days: 1));
                } else {
                  final now = DateTime.now();
                  start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: dias - 1));
                  endExcl = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).add(const Duration(days: 1));
                }
                final days = <DateTime>[];
                final buckets = <DateTime, double>{};
                for (
                  var d = start;
                  d.isBefore(endExcl);
                  d = d.add(const Duration(days: 1))
                ) {
                  final day = DateTime(d.year, d.month, d.day);
                  days.add(day);
                  buckets[day] = 0;
                }
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['timestamp'] as Timestamp?;
                  if (ts == null) continue;
                  final day = DateTime(
                    ts.toDate().year,
                    ts.toDate().month,
                    ts.toDate().day,
                  );
                  final valor = ((data['valor'] ?? 0) as num).toDouble();
                  if (buckets.containsKey(day)) {
                    buckets[day] = (buckets[day] ?? 0) + valor;
                  }
                }
                final spots = <FlSpot>[];
                double maxY = 0;
                for (var i = 0; i < days.length; i++) {
                  final v = buckets[days[i]] ?? 0;
                  if (v > maxY) maxY = v;
                  spots.add(FlSpot(i.toDouble(), v));
                }
                return SizedBox(
                  height: 260,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: maxY > 0 ? maxY / 4 : 1,
                            getTitlesWidget:
                                (v, meta) => Text(
                                  'R\$ ${v.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= days.length)
                                return const SizedBox.shrink();
                              final label = DateFormat('dd/MM').format(days[i]);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
