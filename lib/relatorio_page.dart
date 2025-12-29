import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'package:intl/intl.dart';

class RelatorioPage extends StatelessWidget {
  const RelatorioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/thechosen.png', height: 28),
              const SizedBox(width: 12),
              const Text('Relatórios'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: () => MyApp.requestLogout(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.star), text: 'Ranking'),
              Tab(icon: Icon(Icons.assignment), text: 'Diário'),
              Tab(icon: Icon(Icons.list), text: 'Lançamentos'),
            ],
          ),
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
          child: const TabBarView(
            children: [_RankingTab(), _DiarioTab(), _LancamentosTab()],
          ),
        ),
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lancamentos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum lançamento encontrado.'));
        }
        final docs = snapshot.data!.docs;
        final Map<String, double> ranking = {};
        for (var doc in docs) {
          final id =
              (doc.data() as Map<String, dynamic>)['colportorId'] ??
              'Desconhecido';
          final nome =
              (doc.data() as Map<String, dynamic>)['colportorNome'] ?? id;
          final valor =
              ((doc.data() as Map<String, dynamic>)['valor'] ?? 0).toDouble();
          ranking[nome] = (ranking[nome] ?? 0) + valor;
        }
        final rankingList =
            ranking.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: Image.asset('assets/thechosen.png', height: 72)),
                const SizedBox(height: 12),
                Text(
                  'Ranking de Vendas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
                ...rankingList.asMap().entries.map(
                  (e) => ListTile(
                    leading: CircleAvatar(child: Text('#${e.key + 1}')),
                    title: Text(
                      e.value.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing: Text(
                      "R\$ ${e.value.value.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Nota: Por favor mantenha fidelidade nos lançamentos para garantir rankings justos e relatórios confiáveis.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiarioTab extends StatefulWidget {
  const _DiarioTab();
  @override
  State<_DiarioTab> createState() => _DiarioTabState();
}

class _DiarioTabState extends State<_DiarioTab> {
  DateTime _date = DateTime.now();

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('relatorios_diarios')
              .orderBy('data', descending: true)
              .limit(60)
              .snapshots(),
      builder: (context, dailySnap) {
        if (dailySnap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Erro ao carregar: ${dailySnap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (dailySnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!dailySnap.hasData || dailySnap.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nenhum relatório diário cadastrado.'),
          );
        }
        final all = dailySnap.data!.docs;
        final dateKey = DateFormat(
          'yyyyMMdd',
        ).format(DateTime(_date.year, _date.month, _date.day));
        final docs =
            all.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['dataKey'] ?? '') == dateKey;
            }).toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: docs.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                        child: Image(
                          image: AssetImage('assets/thechosen.png'),
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Relatório Diário do Colportor',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _selecionarData,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Dia: ${DateFormat('dd/MM/yyyy').format(_date)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                if (index == docs.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Nota: Por favor mantenha fidelidade nos lançamentos para garantir rankings justos e relatórios confiáveis.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final d = docs[index - 1];
                final data = d.data() as Map<String, dynamic>;
                final nome =
                    data['colportorNome'] ??
                    data['colportorId'] ??
                    'Desconhecido';
                final ts = (data['data'] as Timestamp?);
                final dia =
                    ts != null
                        ? DateFormat('dd/MM/yyyy').format(ts.toDate())
                        : '-';
                final ofertas = (data['ofertas'] ?? 0) as int;
                final horas = (data['horas'] ?? 0).toDouble();
                final vendas = (data['vendas'] ?? 0).toDouble();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_turned_in),
                    title: Text(
                      '$nome  •  $dia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Ofertas: $ofertas  •  Horas: ${horas.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "R\$ ${vendas.toStringAsFixed(2)}",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Excluir relatório diário',
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text(
                                      'Excluir relatório diário',
                                    ),
                                    content: Text(
                                      'Confirmar exclusão do relatório de $dia para $nome?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              try {
                                final batch =
                                    FirebaseFirestore.instance.batch();
                                batch.delete(d.reference);
                                final ajustes =
                                    await FirebaseFirestore.instance
                                        .collection('lancamentos')
                                        .where('dailyKey', isEqualTo: d.id)
                                        .get();
                                for (final aj in ajustes.docs) {
                                  batch.delete(aj.reference);
                                }
                                await batch.commit();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Relatório diário excluído e ranking atualizado.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao excluir: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LancamentosTab extends StatefulWidget {
  const _LancamentosTab();
  @override
  State<_LancamentosTab> createState() => _LancamentosTabState();
}

class _LancamentosTabState extends State<_LancamentosTab> {
  DateTime _date = DateTime.now();

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusive(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('lancamentos')
              .orderBy('timestamp', descending: true)
              .limit(200)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum lançamento encontrado.'));
        }
        final start = _startOfDay(_date);
        final endEx = _endExclusive(_date);
        final all = snapshot.data!.docs;
        final docs =
            all.where((d) {
              final ts = (d['timestamp'] as Timestamp?);
              if (ts == null) return false;
              final dt = ts.toDate();
              return dt.isAfter(
                    start.subtract(const Duration(microseconds: 1)),
                  ) &&
                  dt.isBefore(endEx);
            }).toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: docs.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                        child: Image(
                          image: AssetImage('assets/thechosen.png'),
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lançamentos',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _selecionarData,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Dia: ${DateFormat('dd/MM/yyyy').format(_date)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                if (index == docs.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Nota: Por favor mantenha fidelidade nos lançamentos para garantir rankings justos e relatórios confiáveis.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final doc = docs[index - 1];
                final data = doc.data() as Map<String, dynamic>;
                final nome =
                    data['colportorNome'] ??
                    data['colportorId'] ??
                    'Desconhecido';
                final valor = (data['valor'] ?? 0).toDouble();
                final ts = (data['timestamp'] as Timestamp?);
                final dataFmt =
                    ts != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate())
                        : '-';
                return ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(
                    nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(dataFmt),
                  trailing: Text(
                    "R\$ ${valor.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
