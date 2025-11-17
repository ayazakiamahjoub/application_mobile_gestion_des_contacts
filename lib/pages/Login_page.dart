import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/database_helper.dart';
import '../main.dart'; // ← IMPORT POUR currentUserId

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      
      await Future.delayed(const Duration(seconds: 1));
      
      final user = await _databaseHelper.loginUser(
        _emailController.text, 
        _passwordController.text
      );
      
      if (mounted) {
        setState(() => _loading = false);
        
        if (user != null) {
          // STOCKE L'UTILISATEUR CONNECTÉ
          currentUserId = user.id;
          print('✅ Utilisateur connecté: ${user.firstName} (ID: $currentUserId)');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Connexion réussie ! Bienvenue ${user.firstName}"),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Email ou mot de passe incorrect"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _register() {
    context.push('/register');
  }

  void _goToDebug() {
    context.push('/debug');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Page de connexion'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.contacts, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    const Text(
                      "Bienvenue 👋",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Veuillez entrer un email";
                        if (!value.contains('@')) return "Email invalide";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Veuillez entrer un mot de passe";
                        if (value.length < 4) return "Mot de passe trop court";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Se connecter", style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _register,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("S'inscrire", style: TextStyle(fontSize: 18)),
                    ),
                    TextButton(
                      onPressed: _goToDebug,
                      child: const Text(
                        "🔧 Debug DB",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}