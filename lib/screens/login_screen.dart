import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/characters_providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nombreCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;

    if (user.isEmpty || pass.isEmpty || (_isRegister && (_nombreCtrl.text.isEmpty || _emailCtrl.text.isEmpty))) {
      setState(() => _error = 'Completa todos los campos obligatorios.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isRegister) {
        await context.read<CharactersProvider>().register(
          nombre: _nombreCtrl.text.trim(), username: user, email: _emailCtrl.text.trim(), password: pass,
        );
      } else {
        await context.read<CharactersProvider>().login(user, pass);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Éxito.')));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Registrarse' : 'Iniciar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 64, color: Colors.amber),
            const SizedBox(height: 20),
            if (_isRegister) ...[
              TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo')),
              const SizedBox(height: 12),
            ],
            TextField(controller: _userCtrl, decoration: InputDecoration(labelText: _isRegister ? 'Usuario' : 'Usuario o Correo')),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator() : Text(_isRegister ? 'Crear Cuenta' : 'Entrar')),
            TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
              child: Text(_isRegister ? '¿Ya tienes cuenta? Ingresa' : '¿Nuevo? Regístrate'),
            )
          ],
        ),
      ),
    );
  }
}