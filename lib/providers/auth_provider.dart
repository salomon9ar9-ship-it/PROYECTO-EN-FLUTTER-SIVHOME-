// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<User?>(
    (_) => FirebaseAuth.instance.authStateChanges());

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users').doc(user.uid).snapshots()
      .map((d) => d.exists ? UserProfile.fromMap(d.data()!, d.id) : null);
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override Future<User?> build() async => FirebaseAuth.instance.currentUser;

  Future<String?> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final c = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      state = AsyncData(c.user);
      return null;
    } on FirebaseAuthException catch (e) {
      state = const AsyncData(null);
      return _msg(e.code);
    } catch (_) {
      state = const AsyncData(null);
      return 'Error inesperado. Intenta de nuevo.';
    }
  }

  Future<String?> register({
    required String name, required String email,
    required String password, required UserRole role,
  }) async {
    state = const AsyncLoading();
    try {
      final c = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);
      await c.user!.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(c.user!.uid)
          .set(UserProfile(uid: c.user!.uid, name: name, email: email,
              role: role, monthlyBudget: 150.0).toMap()
            ..['createdAt'] = FieldValue.serverTimestamp());
      state = AsyncData(c.user);
      return null;
    } on FirebaseAuthException catch (e) {
      state = const AsyncData(null);
      return _msg(e.code);
    }
  }

  Future<void> updateBudget(String uid, double budget) async {
    await FirebaseFirestore.instance.collection('users').doc(uid)
        .update({'monthlyBudget': budget});
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncData(null);
  }

  String _msg(String code) {
    const m = {
      'user-not-found': 'Usuario no encontrado',
      'wrong-password': 'Contraseña incorrecta',
      'invalid-credential': 'Credenciales incorrectas',
      'email-already-in-use': 'El email ya está registrado',
      'weak-password': 'Contraseña muy débil (mín. 6 caracteres)',
      'invalid-email': 'Email inválido',
      'network-request-failed': 'Sin conexión a internet',
    };
    return m[code] ?? 'Error: $code';
  }
}
