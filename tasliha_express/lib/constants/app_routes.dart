import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/client/client_home_screen.dart';
import '../screens/client/post_request_screen.dart';
import '../screens/client/my_requests_screen.dart';
import '../screens/tech/tech_home_screen.dart';
import '../screens/tech/available_requests_screen.dart';
import '../screens/tech/my_jobs_screen.dart';
import '../screens/manager/manager_home_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_requests_screen.dart';
import '../screens/admin/admin_payments_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/chat_screen.dart';
import '../screens/shared/points_screen.dart';
import '../screens/shared/recharge_screen.dart';
import '../screens/shared/rating_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String clientHome = '/client-home';
  static const String postRequest = '/post-request';
  static const String myRequests = '/my-requests';
  static const String techHome = '/tech-home';
  static const String availableRequests = '/available-requests';
  static const String myJobs = '/my-jobs';
  static const String managerHome = '/manager-home';
  static const String adminHome = '/admin-home';
  static const String adminRequests = '/admin-requests';
  static const String adminPayments = '/admin-payments';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String points = '/points';
  static const String recharge = '/recharge';
  static const String rating = '/rating';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _slide(const SplashScreen());
      case login:
        return _slide(const LoginScreen());
      case register:
        return _slide(RegisterScreen(args: settings.arguments as Map<String, dynamic>?));
      case otp:
        return _slide(OtpScreen(args: settings.arguments as Map<String, dynamic>));
      case clientHome:
        return _slide(const ClientHomeScreen());
      case postRequest:
        return _slide(const PostRequestScreen());
      case myRequests:
        return _slide(const MyRequestsScreen());
      case techHome:
        return _slide(const TechHomeScreen());
      case availableRequests:
        return _slide(const AvailableRequestsScreen());
      case myJobs:
        return _slide(const MyJobsScreen());
      case managerHome:
        return _slide(const ManagerHomeScreen());
      case adminHome:
        return _slide(const AdminHomeScreen());
      case adminRequests:
        return _slide(const AdminRequestsScreen());
      case adminPayments:
        return _slide(const AdminPaymentsScreen());
      case profile:
        return _slide(const ProfileScreen());
      case chat:
        return _slide(ChatScreen(args: settings.arguments as Map<String, dynamic>));
      case points:
        return _slide(const PointsScreen());
      case recharge:
        return _slide(const RechargeScreen());
      case rating:
        return _slide(RatingScreen(args: settings.arguments as Map<String, dynamic>));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('الصفحة غير موجودة: ${settings.name}')),
          ),
        );
    }
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
