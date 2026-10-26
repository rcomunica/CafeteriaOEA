import 'package:cafeteria_oea/features/auth/domain/user.dart';
import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:flutter/material.dart';

import '../data/user_admin_repository.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({required this.repository, super.key});

  final UserAdminRepository repository;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = widget.repository.readAll();
  }

  Future<void> _reloadUsers() async {
    final future = widget.repository.readAll();
    setState(() {
      _usersFuture = future;
    });
    await future;
  }

  Future<void> _editUser(User user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormPage(repository: widget.repository, user: user),
      ),
    );
    if (updated == true && mounted) await _reloadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar usuarios')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los usuarios: ${snapshot.error}',
              ),
            );
          }
          final users = snapshot.data ?? const <User>[];
          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }
          return RefreshIndicator(
            onRefresh: _reloadUsers,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                      '${user.email}\n${user.role} · ${user.status}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editUser(user),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class UserFormPage extends StatefulWidget {
  const UserFormPage({required this.repository, required this.user, super.key});

  final UserAdminRepository repository;
  final User user;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.user.email,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.user.phone,
  );
  final _passwordController = TextEditingController();
  late String _role = _roles.contains(widget.user.role)
      ? widget.user.role
      : 'student';
  late String _status = _statuses.contains(widget.user.status)
      ? widget.user.status
      : 'active';
  bool _isLoading = false;
  String? _error;

  static const _roles = ['student', 'admin', 'employee'];
  static const _statuses = ['active', 'inactive'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.repository.updateUser(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _role,
        status: _status,
        password: _passwordController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible actualizar el usuario.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar usuario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña (opcional)',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: _roles
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _role = value!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: _statuses
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;
}
