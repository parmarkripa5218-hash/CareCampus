// CareCampus Widget Boot Test

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carecampus/main.dart';
import 'package:carecampus/services/services.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App Boots and Loads Login Screen', (WidgetTester tester) async {
    // Initialize mock services
    await Services.initialize(forceMock: true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const CareCampusApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify that login screen widgets render
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Your safe space for mental wellness'), findsOneWidget);
  });
}
