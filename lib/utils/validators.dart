class Validators {
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    
    final List<String> missing = [];
    if (value.length < 8) {
      missing.add("8+ characters");
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      missing.add("uppercase letter");
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      missing.add("lowercase letter");
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      missing.add("number");
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      missing.add("special character");
    }
    
    if (missing.isNotEmpty) {
      return "Must contain: ${missing.join(', ')}";
    }
    return null;
  }
}
