import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authenticatedUserProvider = FutureProvider<User>((ref) async {
  final auth = FirebaseAuth.instance;
  final existingUser = auth.currentUser;
  if (existingUser != null) return existingUser;

  final credential = await auth.signInAnonymously();
  return credential.user ?? (throw StateError('Anonymous sign-in failed'));
});
