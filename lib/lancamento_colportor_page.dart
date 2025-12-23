
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'login_page.dart';

class LancamentoColportorPage extends StatefulWidget {
  final String userId;
  final UserRole role;
  final List<String> colportores; // IDs dos colportores cadastrados
  const LancamentoColportorPage({super.key, required this.userId, required this.role, required this.colportores});

  @override
  State<LancamentoColportorPage> createState() => _LancamentoColportorPageState();
}

class _LancamentoColportorPageState extends State<LancamentoColportorPage> {
  final TextEditingController _valorController = TextEditingController();
  String? _erro;
  bool _loading = false;
  String? _colportorSelecionado;
  Map<String, String> _colportorNomes = {};
  bool _carregandoNomes = false;

  @override
  void initState() {
    super.initState();
    if (widget.role == UserRole.colportor) {
      _colportorSelecionado = widget.userId;
    } else {
      _carregarNomesColportores();
    }
  }

  Future<void> _carregarNomesColportores() async {
    setState(() => _carregandoNomes = true);
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final nomes = <String, String>{};
    for (var doc in usersSnap.docs) {
      final id = doc.id;
      final nome = doc['nome'] ?? id;
      if (widget.colportores.contains(id)) {
        nomes[id] = nome;
      }
    }
    setState(() {
      _colportorNomes = nomes;
      _carregandoNomes = false;
    });
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
      // Buscar nome completo do colportor
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_colportorSelecionado).get();
      final nomeColportor = userDoc.data()?['nome'] ?? '';
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
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: const Text('Lançamento de Venda'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.role == UserRole.admin)
              _carregandoNomes
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
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
                      ],
                    ),
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
