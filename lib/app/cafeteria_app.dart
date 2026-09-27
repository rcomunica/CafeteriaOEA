import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/shell/presentation/cafeteria_shell.dart';

class CafeteriaApp extends StatefulWidget {
  const CafeteriaApp({super.key});

  @override
  State<CafeteriaApp> createState() => _CafeteriaAppState();
}

class _CafeteriaAppState extends State<CafeteriaApp> {
  final _authRepository = AuthRepository();
  late final Future<AuthSession?> _restoredSession;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _restoredSession = _restoreSession();
  }

  Future<AuthSession?> _restoreSession() async {
    final session = await _authRepository.loadSession();
    if (mounted) setState(() => _session = session);
    return session;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafetería OEA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FutureBuilder<AuthSession?>(
        future: _restoredSession,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _session == null
              ? LoginPage(
                  onLoggedIn: (session) => setState(() => _session = session),
                )
              : CafeteriaShell(session: _session!);
        },
      ),
    );
  }
}
