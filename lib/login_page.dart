import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserRole { admin, colportor }

class LoginPage extends StatefulWidget {
  final void Function(String userId, UserRole role) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _userId = '';
  UserRole? _role = UserRole.colportor; // pré-selecionado como padrão
  bool _obscure = true;
  String _password = '';
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    setState(() { _loading = true; _error = null; });
    try {
      // Busca usuário no Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        setState(() { _error = 'Usuário não cadastrado!'; _loading = false; });
        return;
      }
      final data = userDoc.data() as Map<String, dynamic>;
      final isAdmin = data['isAdmin'] == true;
      final senhaSalva = data['senha'] as String?;
      if (senhaSalva == null || senhaSalva != _password) {
        setState(() { _error = 'Senha incorreta!'; _loading = false; });
        return;
      }
      // Se usuário marcou ADMIN mas não tem permissão
      if (_role == UserRole.admin && !isAdmin) {
        setState(() { _error = 'Usuário não possui permissão de ADMIN.'; _loading = false; });
        return;
      }
      // Se usuário marcou COLPORTOR mas é admin, permite acesso como admin
      final role = isAdmin ? UserRole.admin : UserRole.colportor;
      widget.onLogin(_userId, role);
    } catch (e) {
      setState(() { _error = 'Erro ao autenticar: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final colorPrimary = const Color(0xFF00695C);
    final colorPrimaryDark = const Color(0xFF004D40);
    final colorSurface = Colors.white;

    return Scaffold(
      body: Container
        (
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorPrimaryDark, const Color(0xFF1B5E57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: baseTextTheme,
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFFF5F7F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          child: Stack(
            children: [
              // Conteúdo principal
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Card(
                        elevation: 10,
                        color: colorSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo e título
                                Center(
                                  child: Column(
                                    children: [
                                      Image.asset('assets/thechosen.png', height: 56),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Acesso Seguro',
                                        style: baseTextTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorPrimaryDark,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Entre para continuar ao painel',
                                        style: baseTextTheme.bodyMedium?.copyWith(color: Colors.black54),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Usuário
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Usuário ou ID',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Informe seu usuário' : null,
                                  onSaved: (v) => _userId = v ?? '',
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: 14),

                                // Perfil
                                DropdownButtonFormField<UserRole>(
                                  decoration: const InputDecoration(
                                    labelText: 'Perfil',
                                    prefixIcon: Icon(Icons.apartment_outlined),
                                  ),
                                  value: _role,
                                  items: const [
                                    DropdownMenuItem(value: UserRole.colportor, child: Text('COLPORTOR')),
                                    DropdownMenuItem(value: UserRole.admin, child: Text('ADMIN')),
                                  ],
                                  validator: (v) => v == null ? 'Selecione o perfil' : null,
                                  onChanged: (v) => setState(() => _role = v),
                                ),

                                const SizedBox(height: 14),

                                // Senha
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  obscureText: _obscure,
                                  validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
                                  onSaved: (v) => _password = v ?? '',
                                  onFieldSubmitted: (_) => _loading ? null : _submit(),
                                ),

                                const SizedBox(height: 18),

                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE5E7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFFC2C6)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFFD32F2F)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                          )
                                        : Text('Entrar', style: baseTextTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // TextButton(
                                //   onPressed: () {
                                //     Navigator.of(context).push(
                                //       MaterialPageRoute(builder: (_) => const CadastroPage()),
                                //     );
                                //   },
                                //   child: const Text('Não tem cadastro? Cadastre-se'),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
