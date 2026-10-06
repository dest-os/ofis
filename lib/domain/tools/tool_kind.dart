enum ToolKind {
  local,
  restApi,
  web,
  file,
  database,
  github,
  email,
  android,
  ai,
}

extension ToolKindX on ToolKind {
  String get value => name.toUpperCase();
}
