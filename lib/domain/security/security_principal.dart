import 'permission_level.dart';
import 'security_scope.dart';

class SecurityPrincipal {
  final String id;
  final String name;
  final PermissionLevel level;
  final SecurityScope scope;
  final bool isFounder;

  const SecurityPrincipal({
    required this.id,
    required this.name,
    required this.level,
    required this.scope,
    this.isFounder = false,
  });
}
