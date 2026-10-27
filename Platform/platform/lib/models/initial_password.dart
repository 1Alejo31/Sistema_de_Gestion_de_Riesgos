import 'dart:math';

/// Generates a temporary credential without relying on predictable randomness.
String generateInitialPassword() {
  final random = Random.secure();
  const groups = [
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'abcdefghijklmnopqrstuvwxyz',
    '0123456789',
    r'!@#$%&*+-=?',
  ];
  final alphabet = groups.join();
  final characters = [
    for (final group in groups) group[random.nextInt(group.length)],
    for (var i = groups.length; i < 24; i++)
      alphabet[random.nextInt(alphabet.length)],
  ];
  characters.shuffle(random);
  return characters.join();
}
