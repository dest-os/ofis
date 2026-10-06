enum EventType {
  taskCreated,
  taskUpdated,
  taskStatusChanged,
  taskAssigned,
  agentStarted,
  agentCompleted,
  approvalRequested,
  approvalResolved,
  aiRequestCreated,
  aiResponseReceived,
  toolRequested,
  toolCompleted,
  memoryWritten,
  archiveWritten,
  notificationCreated,
  systemStarted,
  systemStopped,
  securityAlert,
}

extension EventTypeX on EventType {
  String get value => name.toUpperCase();
}
