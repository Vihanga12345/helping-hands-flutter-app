  // Silence detection for automatic conversation flow
  Timer? _silenceTimer;
  Timer? _maxListeningTimer;
  static const Duration _silenceTimeout = Duration(seconds: 4); // Increased from 3 to 4 seconds
  static const Duration _maxListeningDuration = Duration(seconds: 30);