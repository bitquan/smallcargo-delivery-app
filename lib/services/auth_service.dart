import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // Note: This is a synchronous getter, so it returns a basic user
      // For role-specific data, use the authStateChanges stream instead
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        phoneNumber: firebaseUser.phoneNumber,
        role: UserRole.customer, // Default role - use stream for actual role
        profileImageUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  // Get current user with role from Firestore
  Future<User?> getCurrentUserWithRole() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          return User.fromSnapshot(userDoc);
        }
      } catch (e) {
        print('Error getting user with role: $e');
      }
    }
    return null;
  }

  // Auth state stream
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          // Get user data from Firestore
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (userDoc.exists) {
            return User.fromSnapshot(userDoc);
          } else {
            // Create user document if it doesn't exist
            final user = User(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? '',
              phoneNumber: firebaseUser.phoneNumber,
              role: UserRole.customer,
              profileImageUrl: firebaseUser.photoURL,
              createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
            return user;
          }
        } catch (e) {
          print('Error getting user data: $e');
          return null;
        }
      }
      return null;
    });
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (userDoc.exists) {
          return User.fromSnapshot(userDoc);
        }
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Authentication failed');
    } catch (e) {
      throw AuthException('unknown', 'An unexpected error occurred');
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name, {
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Create user document in Firestore
        final user = User(
          id: credential.user!.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(user.toMap());
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Registration failed');
    } catch (e) {
      throw AuthException('unknown', 'An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear any cached user data
      await _auth.signOut();
      
      // Force reload to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error during sign out: $e');
      // Even if there's an error, try to sign out
      await _auth.signOut();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Password reset failed');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update Firebase Auth profile
      if (name != null) {
        await user.updateDisplayName(name);
      }
      if (profileImageUrl != null) {
        await user.updatePhotoURL(profileImageUrl);
      }

      // Update Firestore document
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return User.fromSnapshot(userDoc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role.name,
      'updatedAt': Timestamp.now(),
    });
  }

  // Force refresh auth state
  Future<void> refreshUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.reload();
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete Firebase Auth account
      await user.delete();
    }
  }
}

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => message;
}
