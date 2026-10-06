enum PermissionLevel { none, read, execute, write, approve, admin }

extension PermissionLevelX on PermissionLevel {
  int get rank => index;
  bool allows(PermissionLevel required) => rank >= required.rank;
}
