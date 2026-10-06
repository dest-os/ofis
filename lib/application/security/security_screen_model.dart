class SecurityScreenModel {
  final String title;
  final int activeRules;
  final int blockedActions;
  final int pendingApprovals;

  const SecurityScreenModel({
    this.title = 'GÜVENLİK MERKEZİ',
    this.activeRules = 0,
    this.blockedActions = 0,
    this.pendingApprovals = 0,
  });
}
