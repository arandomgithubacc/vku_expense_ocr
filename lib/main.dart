import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/app_router.dart';

// void main() {
//   runApp(const ProviderScope(child: MyApp()));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null); // hoặc 'vi_VN'

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const vkuThemeColor = Color(0xFF2C4570);
    return MaterialApp.router(
      title: 'Chi tiêu VKU',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: vkuThemeColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
