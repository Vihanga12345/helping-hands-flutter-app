/// Service to track popup and page display states to prevent duplicates
class PopupStateService {
  static final PopupStateService _instance = PopupStateService._internal();
  factory PopupStateService() => _instance;
  PopupStateService._internal();

  // Track shown popups per job
  final Map<String, Set<String>> _shownPopups = {};

  // Track visited payment pages per job per user
  final Map<String, Map<String, bool>> _visitedPaymentPages = {};

  // Track visited rating pages per job per user
  final Map<String, Map<String, bool>> _visitedRatingPages = {};

  /// Check if popup has already been shown for this job
  bool hasPopupBeenShown(String jobId, String popupType) {
    return _shownPopups[jobId]?.contains(popupType) ?? false;
  }

  /// Mark popup as shown for this job
  void markPopupAsShown(String jobId, String popupType) {
    _shownPopups[jobId] ??= <String>{};
    _shownPopups[jobId]!.add(popupType);
    print('📍 Marked popup as shown: $popupType for job: $jobId');
  }

  /// Check if payment page has been visited for this job by this user
  bool hasPaymentPageBeenVisited(String jobId, String userId) {
    return _visitedPaymentPages[jobId]?[userId] ?? false;
  }

  /// Mark payment page as visited for this job by this user
  void markPaymentPageAsVisited(String jobId, String userId) {
    _visitedPaymentPages[jobId] ??= <String, bool>{};
    _visitedPaymentPages[jobId]![userId] = true;
    print('💳 Marked payment page as visited: $jobId by user: $userId');
  }

  /// Check if rating page has been visited for this job by this user
  bool hasRatingPageBeenVisited(String jobId, String userId) {
    return _visitedRatingPages[jobId]?[userId] ?? false;
  }

  /// Mark rating page as visited for this job by this user
  void markRatingPageAsVisited(String jobId, String userId) {
    _visitedRatingPages[jobId] ??= <String, bool>{};
    _visitedRatingPages[jobId]![userId] = true;
    print('⭐ Marked rating page as visited: $jobId by user: $userId');
  }

  /// Clear all state for a specific job (useful when job is deleted)
  void clearJobState(String jobId) {
    _shownPopups.remove(jobId);
    _visitedPaymentPages.remove(jobId);
    _visitedRatingPages.remove(jobId);
    print('🧹 Cleared all state for job: $jobId');
  }

  /// Clear all states (useful for testing or reset)
  void clearAllStates() {
    _shownPopups.clear();
    _visitedPaymentPages.clear();
    _visitedRatingPages.clear();
    print('🧹 Cleared all popup and page states');
  }

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'shownPopups': _shownPopups,
      'visitedPaymentPages': _visitedPaymentPages,
      'visitedRatingPages': _visitedRatingPages,
    };
  }
}
