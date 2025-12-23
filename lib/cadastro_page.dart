import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, colportor }

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _nomeController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _error;
  bool _loading = false;
  final UserRole _role = UserRole.colportor;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    final userId = _userIdController.text.trim();
    final nome = _nomeController.text.trim();
    final senha = _senhaController.text;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() { _error = 'Usuário já cadastrado!'; _loading = false; });
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'isAdmin': false,
        'nome': nome,
        'senha': senha,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() { _error = 'Erro ao cadastrar: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: const Text('Cadastro de Usuário'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFFB2DFDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _userIdController,
                    decoration: const InputDecoration(labelText: 'Usuário ou ID'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome completo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 4 ? 'Senha deve ter ao menos 4 caracteres' : null,
                  ),
                  const SizedBox(height: 24),
                  // Cadastro apenas como COLPORTOR
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const CircularProgressIndicator() : const Text('Cadastrar'),
                  ),
                 
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
