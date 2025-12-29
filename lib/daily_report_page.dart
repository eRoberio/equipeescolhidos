import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class DailyReportPage extends StatefulWidget {
  final String userId;
  const DailyReportPage({super.key, required this.userId});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  DateTime _date = DateTime.now();
  final TextEditingController _ofertasCtrl = TextEditingController();
  final TextEditingController _horasCtrl = TextEditingController();
  final TextEditingController _vendasCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  String? _colportorNome;

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _carregarConsolidadoVendas();
    _carregarRelatorioExistente();
  }

  Future<void> _carregarNomeUsuario() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _colportorNome =
              (userDoc.data() as Map<String, dynamic>)['nome'] as String?;
        });
      }
    } catch (_) {}
  }

  String _dateKey(DateTime d) =>
      DateFormat('yyyyMMdd').format(DateTime(d.year, d.month, d.day));

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<void> _carregarConsolidadoVendas() async {
    try {
      final start = _startOfDay(_date);
      final end = _endOfDay(_date);
      final snaps =
          await FirebaseFirestore.instance
              .collection('lancamentos')
              .where('colportorId', isEqualTo: widget.userId)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();
      double total = 0;
      for (final d in snaps.docs) {
        final v = (d['valor'] ?? 0).toDouble();
        total += v;
      }
      setState(() {
        _vendasCtrl.text = total.toStringAsFixed(2);
      });
    } catch (_) {}
  }

  Future<double> _sumVendasDoDia() async {
    try {
      final start = _startOfDay(_date);
      final end = _endOfDay(_date);
      final snaps =
          await FirebaseFirestore.instance
              .collection('lancamentos')
              .where('colportorId', isEqualTo: widget.userId)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();
      double total = 0;
      for (final d in snaps.docs) {
        final v = (d['valor'] ?? 0).toDouble();
        total += v;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _carregarRelatorioExistente() async {
    try {
      final key = '${widget.userId}_${_dateKey(_date)}';
      final doc =
          await FirebaseFirestore.instance
              .collection('relatorios_diarios')
              .doc(key)
              .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        // Só preenche se o usuário ainda não começou a digitar
        if (_ofertasCtrl.text.isEmpty &&
            _horasCtrl.text.isEmpty &&
            _vendasCtrl.text.isEmpty) {
          setState(() {
            _ofertasCtrl.text = (data['ofertas'] ?? 0).toString();
            _horasCtrl.text = (data['horas'] ?? 0).toString();
            _vendasCtrl.text = (data['vendas'] ?? 0).toString();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _salvar() async {
    final ofertas = int.tryParse(_ofertasCtrl.text.trim());
    final horas = double.tryParse(_horasCtrl.text.replaceAll(',', '.').trim());
    final vendasText = _vendasCtrl.text.trim();
    final vendas =
        vendasText.isEmpty
            ? 0.0
            : double.tryParse(vendasText.replaceAll(',', '.'));

    if (ofertas == null || ofertas < 0) {
      setState(() => _erro = 'Informe a quantidade de ofertas (0 ou mais).');
      return;
    }
    if (horas == null || horas <= 0) {
      setState(() => _erro = 'Informe as horas trabalhadas (> 0).');
      return;
    }
    if (vendas == null || vendas < 0) {
      setState(
        () =>
            _erro =
                'Informe o valor das vendas (0 ou mais). Campo pode ficar em branco.',
      );
      return;
    }

    setState(() {
      _erro = null;
      _loading = true;
    });
    try {
      final key = '${widget.userId}_${_dateKey(_date)}';
      await FirebaseFirestore.instance
          .collection('relatorios_diarios')
          .doc(key)
          .set({
            'colportorId': widget.userId,
            'colportorNome': _colportorNome,
            'data': Timestamp.fromDate(
              DateTime(_date.year, _date.month, _date.day),
            ),
            'dataKey': _dateKey(_date),
            'ofertas': ofertas,
            'horas': horas,
            'vendas': vendas,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Sincroniza com ranking somente se o campo de vendas foi preenchido
      if (vendasText.isNotEmpty) {
        final somaLancDia = await _sumVendasDoDia();
        final delta = vendas - somaLancDia;
        final lancRef = FirebaseFirestore.instance.collection('lancamentos');
        final ajusteSnap =
            await lancRef
                .where('colportorId', isEqualTo: widget.userId)
                .where('dailyKey', isEqualTo: key)
                .limit(1)
                .get();
        if (ajusteSnap.docs.isNotEmpty) {
          final doc = ajusteSnap.docs.first.reference;
          if (delta.abs() < 0.0001) {
            // Sem diferença: remove ajuste para não duplicar
            await doc.delete();
          } else {
            await doc.set({
              'valor': delta,
              'colportorId': widget.userId,
              'colportorNome': _colportorNome,
              'timestamp': FieldValue.serverTimestamp(),
              'fromDailyReport': true,
              'tipo': 'ajuste_diario',
              'dailyKey': key,
            }, SetOptions(merge: true));
          }
        } else {
          if (delta.abs() >= 0.0001) {
            await lancRef.add({
              'valor': delta,
              'colportorId': widget.userId,
              'colportorNome': _colportorNome,
              'timestamp': FieldValue.serverTimestamp(),
              'fromDailyReport': true,
              'tipo': 'ajuste_diario',
              'dailyKey': key,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório diário salvo!')),
        );
      }
      // Limpa campos e força atualização visual
      FocusScope.of(context).unfocus();
      _ofertasCtrl.clear();
      _horasCtrl.clear();
      _vendasCtrl.clear();
      setState(() {});
    } catch (e) {
      setState(() => _erro = 'Erro ao salvar: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
      await _carregarConsolidadoVendas();
      await _carregarRelatorioExistente();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: const Text('Relatório Diário do Colportor'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => MyApp.requestLogout(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFFB2DFDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/thechosen.png', height: 72)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(_date)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selecionarData,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Alterar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ofertasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de ofertas realizadas',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _horasCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Horas trabalhadas no campo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _vendasCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor total de vendas (consolidado)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _carregarConsolidadoVendas,
                  icon: const Icon(Icons.summarize),
                  label: const Text('Consolidar vendas do dia'),
                ),
              ),
              const SizedBox(height: 8),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label:
                    _loading ? const Text('Salvando...') : const Text('Salvar'),
                onPressed: _loading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Relatórios do dia selecionado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _MeusRelatoriosList(userId: widget.userId, date: _date),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Nota: Por favor mantenha fidelidade nos lançamentos. Relatórios corretos garantem rankings justos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeusRelatoriosList extends StatefulWidget {
  final String userId;
  final DateTime date;
  const _MeusRelatoriosList({required this.userId, required this.date});

  @override
  State<_MeusRelatoriosList> createState() => _MeusRelatoriosListState();
}

class _MeusRelatoriosListState extends State<_MeusRelatoriosList> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    // Evita necessidade de índice composto (where + orderBy) e flicker:
    // carrega os últimos N e filtra por usuário no cliente.
    _stream =
        FirebaseFirestore.instance
            .collection('relatorios_diarios')
            .orderBy('data', descending: true)
            .limit(60)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Erro ao carregar relatórios: ${snap.error}\nTente novamente ou verifique índices do Firestore.',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Text('Nenhum relatório encontrado.');
        }
        final all = snap.data!.docs;
        final String dateKey = DateFormat('yyyyMMdd').format(
          DateTime(widget.date.year, widget.date.month, widget.date.day),
        );
        final docs =
            all.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final uidOk = data['colportorId'] == widget.userId;
              final keyOk = (data['dataKey'] ?? '') == dateKey;
              return uidOk && keyOk;
            }).toList();
        if (docs.isEmpty) {
          return const Text('Nenhum relatório encontrado.');
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final dt = (data['data'] as Timestamp?)?.toDate();
            final dia = dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '-';
            final ofertas = data['ofertas'] ?? 0;
            final horas = (data['horas'] ?? 0).toDouble();
            final vendas = (data['vendas'] ?? 0).toDouble();
            return Card(
              child: ListTile(
                title: Text('Dia $dia'),
                subtitle: Text(
                  'Ofertas: $ofertas  •  Horas: ${horas.toStringAsFixed(2)}',
                ),
                trailing: Text('R\$ ${vendas.toStringAsFixed(2)}'),
              ),
            );
          },
        );
      },
    );
  }
}
