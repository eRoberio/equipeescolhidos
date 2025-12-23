import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class LancamentosPage extends StatefulWidget {
  const LancamentosPage({super.key});

  @override
  State<LancamentosPage> createState() => _LancamentosPageState();
}

class _LancamentosPageState extends State<LancamentosPage> {
  final TextEditingController _valorController = TextEditingController();
  String? _erro;
  bool _loading = false;
  String? _colportorSelecionado;
  Map<String, String> _colportorNomes = {};
  bool _carregandoNomes = false;

  @override
  void initState() {
    super.initState();
    _carregarNomesColportores();
  }

  Future<void> _carregarNomesColportores() async {
    setState(() => _carregandoNomes = true);
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final nomes = <String, String>{};
      for (var doc in usersSnap.docs) {
        final id = doc.id;
        final nome = doc['nome'] ?? id;
        nomes[id] = nome;
      }
      setState(() {
        _colportorNomes = nomes;
        _carregandoNomes = false;
      });
    } catch (e) {
      setState(() {
        _colportorNomes = {};
        _carregandoNomes = false;
      });
    }
  }

  Future<void> _salvarLancamento() async {
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor válido (> 0)');
      return;
    }
    if (_colportorSelecionado == null) {
      setState(() => _erro = 'Selecione o colportor');
      return;
    }
    setState(() { _erro = null; _loading = true; });
    try {
      final nomeColportor = _colportorNomes[_colportorSelecionado] ?? '';
      await FirebaseFirestore.instance.collection('lancamentos').add({
        'valor': valor,
        'colportorId': _colportorSelecionado,
        'colportorNome': nomeColportor,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _valorController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento salvo com sucesso!')),
      );
    } catch (e) {
      setState(() => _erro = 'Erro ao salvar: $e');
    } finally {
      setState(() => _loading = false);
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
            const Text('Lançamentos'),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF1B5E57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: _carregandoNomes
            ? const Center(child: CircularProgressIndicator())
            : _colportorNomes.isEmpty
                ? const Center(child: Text('Nenhum colportor cadastrado. Cadastre pelo menos um para lançar vendas.'))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _colportorSelecionado,
                        items: _colportorNomes.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _colportorSelecionado = v),
                        decoration: const InputDecoration(labelText: 'Colportor'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Valor da venda',
                          errorText: _erro,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _salvarLancamento(),
                        enabled: !_loading,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: _loading ? const Text('Salvando...') : const Text('Salvar'),
                        onPressed: _loading ? null : _salvarLancamento,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ),
      ),
      ),
    );
  }
}
