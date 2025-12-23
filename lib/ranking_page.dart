
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Ranking de Vendas'),
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
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('lancamentos').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhum lançamento encontrado.'));
            }
            final docs = snapshot.data!.docs;
            final Map<String, double> ranking = {};
            final Map<String, String> nomes = {};
            for (var doc in docs) {
              final id = doc['colportorId'] ?? 'Desconhecido';
              final nome = doc['colportorNome'] ?? id;
              final valor = (doc['valor'] ?? 0).toDouble();
              ranking[id] = (ranking[id] ?? 0) + valor;
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
                    subtitle: Text('Total: R\$ ${valor.toStringAsFixed(2)}'),
                    trailing: Icon(
                      Icons.emoji_events,
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
    );
  }
}
