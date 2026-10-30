// Security Input Validation & Sanitization Controls

class Validators {
  /// Validates that an email format is correct.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or username is required.';
    }
    final trimmed = value.trim();
    // Allow standard email or basic admin username
    if (trimmed == 'admin' || trimmed == 'counsellor' || trimmed == 'student') {
      return null; // allow mock shortcuts
    }
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password strength:
  /// - Min 8 characters
  /// - Min 1 uppercase letter
  /// - Min 1 lowercase letter
  /// - Min 1 number
  /// - Min 1 special character
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit.';
    }
    if (!RegExp(r'[!@#\$&*~%^()_\-+={[\]|:;"<,>.?\/]').hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  /// Sanitizes text inputs by removing HTML tags and script contents to prevent XSS injection.
  static String sanitizeText(String text) {
    // Strip script blocks and their content entirely
    final scriptTagsExp = RegExp(r'<script\b[^>]*>([\s\S]*?)<\/script>', multiLine: true, caseSensitive: false);
    final noScripts = text.replaceAll(scriptTagsExp, '');

    // Strip remaining HTML tags
    final htmlTagsExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return noScripts.replaceAll(htmlTagsExp, '').trim();
  }

  /// Standard text field validation for general inputs
  static String? validateRequired(String? value, String fieldName, {int maxLen = 500}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final sanitized = sanitizeText(value);
    if (sanitized.isEmpty) {
      return '$fieldName contains invalid characters.';
    }
    if (sanitized.length > maxLen) {
      return '$fieldName cannot exceed $maxLen characters.';
    }
    return null;
  }

  /// Validates URL formats for wellness resource uploads
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Resource URL is required.';
    }
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlPattern.hasMatch(value.trim())) {
      return 'Please enter a valid URL (e.g., https://example.com/resource).';
    }
    return null;
  }
}
