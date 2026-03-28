import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/widgets/loading_button.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _role = widget.user?.role ?? 'vendedor';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,
    };

    if (_passwordController.text.isNotEmpty) {
      userData['password'] = _passwordController.text;
    }

    try {
      if (widget.user == null) {
        if (_passwordController.text.isEmpty) {
          throw Exception('La contraseña es requerida para nuevos usuarios.');
        }
        await context.read<UserProvider>().addUser(userData);
      } else {
        await context.read<UserProvider>().updateUser(widget.user!.id, userData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person_outline)),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol del Usuario', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                ],
                onChanged: (val) => setState(() => _role = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña Inicial',
                  hintText: isEditing ? 'Dejar en blanco para no cambiar' : null,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (val) {
                  if (!isEditing && (val == null || val.isEmpty)) return 'Requerido';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              LoadingButton(
                text: isEditing ? 'ACTUALIZAR USUARIO' : 'CREAR USUARIO',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
