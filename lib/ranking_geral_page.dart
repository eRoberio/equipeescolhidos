
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'login_page.dart';

class RankingGeralPage extends StatelessWidget {
  final UserRole role;
  const RankingGeralPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Ranking Geral da Campanha'),
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
      body: _RankingGeralBody(role: role),
    );
  }
}

class _RankingGeralBody extends StatefulWidget {
  final UserRole role;
  const _RankingGeralBody({required this.role});
  @override
  State<_RankingGeralBody> createState() => _RankingGeralBodyState();
}

class _RankingGeralBodyState extends State<_RankingGeralBody> {
  bool _pontuando = false;
  bool _removendo = false;
  String? _colportorSelecionado;
  Map<String, String> _colportorNomes = {};
  bool _carregandoNomes = false;
  final _pontosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarNomesColportores();
  }

  Future<void> _carregarNomesColportores() async {
    setState(() => _carregandoNomes = true);
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
  }

  Future<void> _pontuarColportor() async {
    final pontos = int.tryParse(_pontosController.text);
    if (_colportorSelecionado == null || pontos == null || pontos <= 0) return;
    final signed = _removendo ? -pontos : pontos;
    await FirebaseFirestore.instance.collection('pontos_gerais').add({
      'colportorId': _colportorSelecionado,
      'colportorNome': _colportorNomes[_colportorSelecionado],
      'pontos': signed,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _pontosController.clear();
    setState(() => _pontuando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_removendo ? 'Pontos removidos!' : 'Pontuação registrada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF0E2A26), Color(0xFF1B5E57)]
              : const [Colors.white, Color(0xFFEFF7F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (widget.role == UserRole.admin) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Color(0xFF00695C)),
              label: const Text('Pontuar Colportor agora!', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2DFDB),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () => setState(() { _pontuando = true; _removendo = false; }),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_circle, color: Colors.white),
              label: const Text('Remover Pontos', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () => setState(() { _pontuando = true; _removendo = true; }),
            ),
          ],
          if (_pontuando && widget.role == UserRole.admin)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _carregandoNomes
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
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
                        controller: _pontosController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _removendo ? 'Pontos a remover' : 'Pontos a adicionar',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _pontuando = false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _pontuarColportor,
                            child: Text(_removendo ? 'Remover Pontos' : 'Salvar Pontos'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('pontos_gerais').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhuma pontuação registrada ainda.'));
                }
                final docs = snapshot.data!.docs;
                final Map<String, int> ranking = {};
                final Map<String, String> nomes = {};
                for (var doc in docs) {
                  final id = doc['colportorId'] ?? 'Desconhecido';
                  final nome = doc['colportorNome'] ?? id;
                  final pontos = (doc['pontos'] ?? 0) as int;
                  ranking[id] = (ranking[id] ?? 0) + pontos;
                  nomes[id] = nome;
                }
                final rankingList = ranking.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
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
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
                        subtitle: Text('Pontos: $valor'),
                        trailing: Icon(
                          Icons.star,
                          color: index == 0
                              ? Colors.amber
                              : (index == 1
                                  ? Colors.grey
                                  : (index == 2 ? Colors.brown : Colors.blueGrey)),
                          size: 32,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 