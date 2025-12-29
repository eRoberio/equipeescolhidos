import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ranking_page.dart';
import 'ranking_geral_page.dart';
import 'charts_page.dart';
import 'ranking_ofertas_page.dart';
import 'ranking_horas_page.dart';
import 'package:thechosenrankin/relatorio_page.dart';
import 'goal_dashboard.dart';
import 'lancamentos_page.dart';
import 'nova_campanha_page.dart';
import 'login_page.dart';
import 'daily_report_page.dart';
import 'semana_maxima_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyA2naYhASRdNdxMTVtRe2o_jGtW3nxPExk',
      appId: '1:600560999206:android:c4b72be9797da5cc947fe7',
      messagingSenderId: '600560999206',
      projectId: 'thechosen-2432f',
      storageBucket: 'thechosen-2432f.firebasestorage.app',
    ),
  );
  runApp(MyApp(key: MyApp.globalKey));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<_MyAppState> globalKey = GlobalKey<_MyAppState>();

  static void requestLogout() {
    globalKey.currentState?._logout();
  }

  static void requestToggleTheme() {
    globalKey.currentState?._toggleTheme();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String? _userId;
  UserRole? _role;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  void _onLogin(String userId, UserRole role) async {
    setState(() {
      _userId = userId;
      _role = role;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('role', role.name);
  }

  void _logout() async {
    setState(() {
      _userId = null;
      _role = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('role');
  }
  @override
  void initState() {
    super.initState();
    _restaurarLogin();
  }

  Future<void> _restaurarLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final roleStr = prefs.getString('role');
    if (userId != null && roleStr != null) {
      UserRole? role;
      if (roleStr == 'admin') {
        role = UserRole.admin;
      } else if (roleStr == 'colportor') {
        role = UserRole.colportor;
      }
      if (role != null) {
        setState(() {
          _userId = userId;
          _role = role;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF00695C);
    final colorPrimaryDark = const Color(0xFF004D40);
    final lightScheme = ColorScheme.fromSeed(seedColor: colorPrimary);
    final darkScheme = ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: colorPrimary);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Equipe Escolhidos',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: colorPrimaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F7F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      themeMode: _themeMode,
      home: _userId == null || _role == null
          ? LoginPage(onLogin: _onLogin)
          : HomeMenuPage(
              userId: _userId!,
              role: _role!,
              onLogout: _logout,
            ),
    );
  }
}

class HomeMenuPage extends StatelessWidget {
  final String userId;
  final UserRole role;
  final VoidCallback onLogout;
  const HomeMenuPage({super.key, required this.userId, required this.role, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF00695C);
    final colorPrimaryDark = const Color(0xFF004D40);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/thechosen.png', height: 28),
            const SizedBox(width: 12),
            const Text('Menu'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Alternar tema',
            onPressed: MyApp.requestToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: onLogout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorPrimaryDark, const Color(0xFF1B5E57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/thechosen.png', height: 40),
                            const SizedBox(width: 12),
                            Text('Selecione uma opção', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.black.withOpacity(0.08)),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (role == UserRole.colportor)
                              _MenuTile(
                                icon: Icons.assignment,
                                title: 'Relatório Diário',
                                subtitle: 'Envie o seu progresso diário',
                                color: colorPrimary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => DailyReportPage(userId: userId)),
                                  );
                                },
                              ),
                            _MenuTile(
                              icon: Icons.emoji_events,
                              title: 'Ranking de Vendas',
                              subtitle: 'Veja sua posição e metas',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RankingPage()),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.list_alt,
                              title: 'Ranking de Ofertas',
                              subtitle: 'Quantidade de ofertas realizadas',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RankingOfertasPage()),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.timelapse,
                              title: 'Ranking de Horas',
                              subtitle: 'Horas trabalhadas no campo',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RankingHorasPage()),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.star,
                              title: 'Ranking Geral',
                              subtitle: 'Pontuações agregadas',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => RankingGeralPage(role: role)),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.pie_chart,
                              title: 'Gráficos',
                              subtitle: 'Análises visuais',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ChartsPage()),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.calendar_today,
                              title: 'Semana Máxima',
                              subtitle: role == UserRole.admin ? 'Configurar período e ver ranking' : 'Ranking da semana máxima',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SemanaMaximaPage(role: role)),
                                );
                              },
                            ),
                            _MenuTile(
                              icon: Icons.dashboard,
                              title: 'Painel',
                              subtitle: 'Metas e acompanhamento',
                              color: colorPrimary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => GoalDashboardPage(userId: userId, role: role)),
                                );
                              },
                            ),
                            if (role == UserRole.admin) ...[
                              _MenuTile(
                                icon: Icons.edit,
                                title: 'Lançamentos',
                                subtitle: 'Gestão de registros',
                                color: colorPrimary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const LancamentosPage()),
                                  );
                                },
                              ),
                              _MenuTile(
                                icon: Icons.bar_chart,
                                title: 'Relatório',
                                subtitle: 'Consolidados e exportações',
                                color: colorPrimary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RelatorioPage()),
                                  );
                                },
                              ),
                              _MenuTile(
                                icon: Icons.flag,
                                title: 'Nova Campanha',
                                subtitle: 'Configurar objetivos',
                                color: colorPrimary,
                                onTap: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NovaCampanhaPage()),
                                  );
                                  if (result == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Campanha criada com sucesso!')),
                                    );
                                  }
                                },
                              ),
                              _DangerTile(
                                icon: Icons.delete_forever,
                                title: 'Resetar Tudo',
                                subtitle: 'Apagar lançamentos e pontos gerais',
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Resetar Tudo'),
                                      content: const Text('Tem certeza que deseja apagar TODOS os lançamentos e pontuações gerais?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Apagar')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final batch = FirebaseFirestore.instance.batch();
                                    final lancSnaps = await FirebaseFirestore.instance.collection('lancamentos').get();
                                    for (final doc in lancSnaps.docs) {
                                      batch.delete(doc.reference);
                                    }
                                    final pontosSnaps = await FirebaseFirestore.instance.collection('pontos_gerais').get();
                                    for (final doc in pontosSnaps.docs) {
                                      batch.delete(doc.reference);
                                    }
                                    await batch.commit();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Todos os dados foram apagados (lançamentos e pontos gerais)!')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DangerTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_forever, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFD32F2F))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFB71C1C))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
