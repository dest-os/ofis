enum DatabaseOperation {
  insert,
  update,
  delete,
  read,
}

extension DatabaseOperationX on DatabaseOperation {
  String get value => name.toUpperCase();
}
