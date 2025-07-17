enum UserType {
  helpee,
  helper,
  admin;

  String get displayName {
    switch (this) {
      case UserType.helpee:
        return 'Helpee';
      case UserType.helper:
        return 'Helper';
      case UserType.admin:
        return 'Admin';
    }
  }
}
