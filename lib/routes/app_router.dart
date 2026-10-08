import 'package:go_router/go_router.dart';

import '../models/expense_item.dart';
import '../screens/home_screen.dart';
import '../screens/review_screen.dart';
import '../screens/scan_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const scan = '/scan';
  static const review = '/review';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.scan,
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: AppRoutes.review,
      name: 'review',
      builder: (context, state) {
        final extra = state.extra;
        return ReviewScreen(expense: extra is ExpenseItem ? extra : null);
      },
    ),
  ],
);
