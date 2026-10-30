import 'dart:math';

/// Anonymization utilities for student privacy in the counselling platform.
class SecurityUtils {
  static const List<String> _adjectives = [
    'Calm', 'Serene', 'Peaceful', 'Gentle', 'Quiet', 'Mindful', 'Resilient', 
    'Hopeful', 'Strong', 'Brave', 'Kind', 'Wise', 'Healing', 'Steady', 'Patient'
  ];

  static const List<String> _nouns = [
    'River', 'Forest', 'Mountain', 'Ocean', 'Sky', 'Garden', 'Meadow', 
    'Willow', 'Pebble', 'Cove', 'Lotus', 'Breeze', 'Sun', 'Star', 'Heron'
  ];

  /// Generates a randomized pseudonym (e.g., "Calm Meadow-482") to keep forum 
  /// and chatbot assessment reports anonymous while remaining friendly and readable.
  static String generatePseudonym(String uid) {
    // Seed random generator with UID hash to keep it consistent per student session
    final seed = uid.hashCode;
    final rand = Random(seed);
    
    final adj = _adjectives[rand.nextInt(_adjectives.length)];
    final noun = _nouns[rand.nextInt(_nouns.length)];
    final number = rand.nextInt(900) + 100; // 100-999
    
    return '$adj$noun-$number';
  }

  /// Obscures a student ID for database lookup logs
  static String maskId(String id) {
    if (id.length <= 4) return '****';
    return id.substring(0, 2) + '*' * (id.length - 4) + id.substring(id.length - 2);
  }
}
