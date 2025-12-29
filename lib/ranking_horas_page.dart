import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RankingHorasPage extends StatelessWidget {
  const RankingHorasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Ranking de Horas no Campo'),
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
          future: FirebaseFirestore.instance.collection('relatorios_diarios').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhum relatório diário encontrado.'));
            }
            final docs = snapshot.data!.docs;
            final Map<String, double> ranking = {};
            final Map<String, String> nomes = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final id = (data['colportorId'] ?? 'Desconhecido').toString();
              final nome = (data['colportorNome'] ?? id).toString();
              final horas = ((data['horas'] ?? 0) as num).toDouble();
              ranking[id] = (ranking[id] ?? 0) + horas;
              nomes[id] = nome;
            }
            if (ranking.isEmpty) {
              return const Center(child: Text('Nenhuma hora registrada.'));
            }
            final rankingList = ranking.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: rankingList.length,
              itemBuilder: (context, index) {
                final entry = rankingList[index];
                final nome = nomes[entry.key] ?? entry.key;
                final totalHoras = entry.value;
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
                    subtitle: Text('Horas: ${totalHoras.toStringAsFixed(2)} h'),
                    trailing: const Icon(Icons.timelapse, color: Colors.teal, size: 28),
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
