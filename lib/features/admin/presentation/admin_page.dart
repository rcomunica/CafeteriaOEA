import 'package:cafeteria_oea/features/admin/presentation/scanner_page.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final silvers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        sliver: SliverToBoxAdapter(child: const _AdminHeader()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Administración',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(child: const _AdminCards()),
      ),
    ];
    return CustomScrollView(slivers: silvers);
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  // final AdminItem admin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          // backgroundImage: AssetImage('assets/images/admin_picture.png'),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuario Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'admin@cafeteria.test',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminCards extends StatelessWidget {
  const _AdminCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear QR'),
            onTap: () {
              // Navegar a la página de escaneo de QR
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrScannerScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.import_contacts),
            title: const Text('Ver Ordenes'),
            onTap: () {
              // Navegar a la página de configuración
            },
          ),
        ),
      ],
    );
  }
}
