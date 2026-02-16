import 'package:flutter/material.dart';
import 'package:my_house_app/screens/about.dart';
import 'package:my_house_app/screens/admin_dashboard_screen.dart';
import 'package:my_house_app/screens/admin_edit_user_screen.dart';
import 'package:my_house_app/screens/admin_manage_users_screen.dart';
import 'package:my_house_app/screens/admin_reports_screen.dart';
import 'package:my_house_app/screens/admin_unpaid_agents_screen.dart';
import 'package:my_house_app/screens/admin_unpaid_posts_screen.dart';
import 'package:my_house_app/screens/agent_details_screen.dart';
import 'package:my_house_app/screens/agent_request_screen.dart';
import 'package:my_house_app/screens/edit_profile_screen.dart';
import 'package:my_house_app/screens/my_posts_screen.dart';
import 'package:my_house_app/screens/update_post_screen.dart';
import 'package:my_house_app/screens/user_dashboard_screen.dart';
import 'package:my_house_app/screens/view_profile_screen.dart';
import 'utils/navigation_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/about_screen.dart';
import 'screens/agents_screen.dart';
import 'screens/post_house_screen.dart';
import 'widgets/auth_gate.dart'; // optional - if you created it
import 'theme.dart'; // <-- import the shared theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MkorishopApp());
}

class MkorishopApp extends StatelessWidget {
  const MkorishopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gethouse',
      navigatorKey: NavigationService.navigatorKey, // <- important
      debugShowCheckedModeBanner: false,
      theme: appTheme, // <-- apply the shared theme here
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignupScreen(),
        '/about': (context) => const AboutScreen(),
         '/about_programmer': (context) => const ContactScreen(),
        '/agents': (context) => const AgentsScreen(),
        
         '/admin-dashboard': (context) => const  AuthGate(child: AdminDashboardScreen()),
        '/post-house': (context) => const AuthGate(child: PostHouseScreen()),
        '/user-dashboard': (c) => const AuthGate(child: UserDashboardScreen()),
        '/view-profile': (c) => const AuthGate(child: ViewProfileScreen()),
        '/edit-profile': (c) => const AuthGate(child: EditProfileScreen()),
        // '/update-post': (c) => const AuthGate(child: UpdatePostScreen()),
        '/agent-request': (c) => const AuthGate(child: AgentRequestScreen()),
        '/update-post': (c) => const AuthGate(child: PostHouseScreen()),
        // '/admin': (c) => const AdminDashboardScreen(),
        '/admin/unpaid-posts': (c) => const AuthGate(child: AdminUnpaidPostsScreen()),
        '/admin/unpaid-agents': (c) => const AuthGate(child: AdminUnpaidAgentsScreen()),
        '/admin/manage-users': (c) => const AuthGate(child: AdminManageUsersScreen()),
        '/admin/reports': (c) => const  AuthGate(child: AdminReportsScreen()), 
      '/admin/edit-user': (c) => const  AuthGate(child: AdminEditUserScreen()), 
      },
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          final uri = Uri.parse(name);
        // Handle /signin?redirect=...
        if (settings.name != null && settings.name!.startsWith('/signin')) {
          return MaterialPageRoute(
            builder: (context) => const SigninScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/edit-profile')) {
          return MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/my-posts')) {
          return MaterialPageRoute(
            builder: (context) => const MyPostsScreen2(),
            settings: settings,
          );
        }
          if (settings.name != null && settings.name!.startsWith('/view-profile')) {
          return MaterialPageRoute(
            builder: (context) => const ViewProfileScreen(),
            settings: settings,
          );
        }
        if (settings.name != null && settings.name!.startsWith('/update-post')) {
          return MaterialPageRoute(
            builder: (context) => const UpdatePostScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/agent-request')) {
          return MaterialPageRoute(
            builder: (context) => const AgentRequestScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/post-house')) {
          return MaterialPageRoute(
            builder: (context) => const PostHouseScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/user-dashboard')) {
          return MaterialPageRoute(
            builder: (context) => const UserDashboardScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/admin-dashboard')) {
          return MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/about_programmer')) {
          return MaterialPageRoute(
            builder: (context) => const ContactScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/about')) {
          return MaterialPageRoute(
            builder: (context) => const AboutScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/agents')) {
          return MaterialPageRoute(
            builder: (context) => const AgentsScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/home')) {
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
            settings: settings,
          );
        }
         if (settings.name != null && settings.name!.startsWith('/admin/edit-user')) {
          return MaterialPageRoute(
            builder: (context) => const AdminEditUserScreen(),
            settings: settings,
          );
        }
          if (uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'agent' &&
      uri.pathSegments[1] == 'update') {
    final id = int.tryParse(uri.pathSegments[2]).toString();
    return MaterialPageRoute(
      builder: (_) => AgentEditScreen(agentId: id),
      settings: settings,
    );
    }
  if (uri.pathSegments.length == 3 &&
      uri.pathSegments[0] == 'agent' &&
      uri.pathSegments[1] == 'details') {
    final id = int.tryParse(uri.pathSegments[2]).toString();
    return MaterialPageRoute(
      builder: (_) => AgentDetailsScreen(agentId: id),
      settings: settings,
    );
    }
        // Add similar logic for other routes if needed
        return null; // fallback to onUnknownRoute
      },
      
    );
  }
}

