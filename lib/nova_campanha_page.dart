import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class NovaCampanhaPage extends StatefulWidget {
  const NovaCampanhaPage({super.key});

  @override
  State<NovaCampanhaPage> createState() => _NovaCampanhaPageState();
}

class _NovaCampanhaPageState extends State<NovaCampanhaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _metaController = TextEditingController();
  DateTime? _dataFinal;
  bool _loading = false;
  String? _erro;

  Future<void> _criarCampanha() async {
    if (!_formKey.currentState!.validate() || _dataFinal == null) return;
    setState(() { _loading = true; _erro = null; });
    try {
      await FirebaseFirestore.instance.collection('campanhas').add({
        'meta': double.parse(_metaController.text.replaceAll(',', '.')),
        'dataFinal': _dataFinal,
        'criadaEm': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erro = 'Erro ao criar campanha: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: const Text('Nova Campanha'),
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
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _metaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Meta (R\$)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) {
                  final valor = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (valor == null || valor <= 0) return 'Informe um valor válido (> 0)';
                  return null;
                },
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataFinal == null
                          ? 'Escolher data/hora final'
                          : '${_dataFinal!.day.toString().padLeft(2, '0')}/'
                            '${_dataFinal!.month.toString().padLeft(2, '0')}/'
                            '${_dataFinal!.year} '
                            '${_dataFinal!.hour.toString().padLeft(2, '0')}:${_dataFinal!.minute.toString().padLeft(2, '0')}'),
                      onPressed: _loading ? null : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _dataFinal = DateTime(
                                picked.year, picked.month, picked.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: _loading ? const Text('Salvando...') : const Text('Criar Campanha'),
                onPressed: _loading ? null : _criarCampanha,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
