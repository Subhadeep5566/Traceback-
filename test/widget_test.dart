import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/main.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TracebackApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();
    await tester.pumpWidget(TracebackApp(storageService: storageService));
    await tester.pump();

    // Verify TRACEBACK title renders
    expect(find.text('TRACEBACK'), findsOneWidget);
  });
}