import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/common/presentation/remote_state.dart';
import 'package:qualitrack_mobile/common/presentation/view_status.dart';
import 'package:qualitrack_mobile/laboratory/domain/entities/pharmaceutical_product.dart';
import 'package:qualitrack_mobile/laboratory/domain/entities/product_catalog.dart';
import 'package:qualitrack_mobile/laboratory/presentation/bloc/products_bloc.dart';
import 'package:qualitrack_mobile/laboratory/presentation/screens/products_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockProductsBloc extends MockBloc<ProductsEvent, ProductsState> implements ProductsBloc {}

void main() {
  testWidgets('counts a single product in the singular', (tester) async {
    final bloc = MockProductsBloc();
    when(() => bloc.state).thenReturn(
      const ProductsState(
        remote: RemoteState(
          status: ViewStatus.success,
          data: ProductCatalog(
            environments: [storage],
            products: [
              PharmaceuticalProduct(id: 1, environmentId: 3, code: 'IBU-400', name: 'Ibuprofen 400mg', active: true),
            ],
          ),
        ),
      ),
    );
    final screen = BlocProvider<ProductsBloc>.value(value: bloc, child: const ProductsScreen());

    await tester.pumpLocalized(screen);
    expect(find.text('1 registered product'), findsOneWidget);

    await tester.pumpLocalized(screen, locale: const Locale('es'));
    expect(find.text('1 producto registrado'), findsOneWidget);
  });
}
