import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_guard_service.dart';

/// Route guard middleware for protecting routes based on user type
class RouteGuard {
  static final AuthGuardService _authGuard = AuthGuardService();

  /// Create a route guard that checks user permissions before allowing access
  static Future<String?> guardRoute(
    BuildContext context,
    GoRouterState state,
  ) async {
    final route = state.uri.path;

    print('🔒 Route guard checking access to: $route');

    try {
      final accessResult = await _authGuard.checkRouteAccess(route);

      if (accessResult.isAllowed) {
        print('✅ Access granted to: $route');
        return null; // Allow access
      } else {
        print('❌ Access denied to: $route - ${accessResult.reason}');

        // Handle forced logout if required
        if (accessResult.shouldLogout) {
          await _authGuard.forceLogoutForSecurity(
              accessResult.reason ?? 'Unauthorized access');
        }

        // Show error message to user only if context is available and mounted
        if (context.mounted) {
          _showAccessDeniedSnackBar(
              context, accessResult.reason ?? 'Access denied');
        }

        // Redirect to appropriate page
        return accessResult.redirectTo ?? '/user-selection';
      }
    } catch (e) {
      print('❌ Route guard error: $e');
      return '/user-selection'; // Fallback to user selection
    }
  }

  /// Show access denied snackbar to user (safer than dialog)
  static void _showAccessDeniedSnackBar(BuildContext context, String reason) {
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access Denied: $reason',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      // If even SnackBar fails, just print to console
      print('⚠️ Could not show access denied message: $reason');
    }
  }

  /// Check if user can access a specific route (for UI elements)
  static Future<bool> canAccessRoute(String route) async {
    try {
      final accessResult = await _authGuard.checkRouteAccess(route);
      return accessResult.isAllowed;
    } catch (e) {
      print('❌ Error checking route access: $e');
      return false;
    }
  }

  /// Get appropriate home page for current user
  static String getHomePageForCurrentUser() {
    // This will be handled by the auth guard service
    return '/user-selection';
  }
}

/// Widget that conditionally shows content based on route access
class ConditionalRouteWidget extends StatefulWidget {
  final String requiredRoute;
  final Widget child;
  final Widget? fallback;

  const ConditionalRouteWidget({
    Key? key,
    required this.requiredRoute,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  State<ConditionalRouteWidget> createState() => _ConditionalRouteWidgetState();
}

class _ConditionalRouteWidgetState extends State<ConditionalRouteWidget> {
  bool _hasAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final hasAccess = await RouteGuard.canAccessRoute(widget.requiredRoute);
    if (mounted) {
      setState(() {
        _hasAccess = hasAccess;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasAccess) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Mixin for pages that need route protection
mixin RouteProtectedMixin<T extends StatefulWidget> on State<T> {
  late String protectedRoute;
  bool _accessChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRouteAccess();
    });
  }

  Future<void> _checkRouteAccess() async {
    if (_accessChecked) return;
    _accessChecked = true;

    final hasAccess = await RouteGuard.canAccessRoute(protectedRoute);
    if (!hasAccess && mounted) {
      // Redirect to appropriate page
      context.go('/user-selection');
    }
  }
}

/// Extension for easy route protection in widgets
extension RouteProtectionExtension on BuildContext {
  /// Check if current user can access a route
  Future<bool> canAccess(String route) async {
    return await RouteGuard.canAccessRoute(route);
  }

  /// Navigate only if user has access
  Future<void> goIfAllowed(String route) async {
    final hasAccess = await RouteGuard.canAccessRoute(route);
    if (hasAccess) {
      go(route);
    } else {
      // Show access denied message
      if (mounted) {
        ScaffoldMessenger.of(this).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to access this page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
