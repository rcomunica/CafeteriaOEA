// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:cafeteria_oea/features/auth/data/auth_repository.dart';
import 'package:cafeteria_oea/features/auth/domain/user.dart';
import 'package:cafeteria_oea/features/menu/data/mock_menu.dart';
import 'package:cafeteria_oea/features/shell/presentation/cafeteria_shell.dart';

void main() {
  testWidgets('muestra el menu mock y permite agregar al carrito', (
    tester,
  ) async {
    const session = AuthSession(
      token: 'test-token',
      expiresAt: null,
      user: User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        phone: '',
        role: 'employee',
        status: 'active',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CafeteriaShell(
          session: session,
          menuFuture: Future.value(mockMenu),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menú de hoy'), findsOneWidget);
    expect(find.text('Producto mock 01'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar al carrito').first);
    await tester.pump();

    await tester.tap(find.text('Carrito'));
    await tester.pump();

    expect(find.text('Tu carrito'), findsOneWidget);
    expect(find.text('Producto mock 01'), findsOneWidget);
  });
}
