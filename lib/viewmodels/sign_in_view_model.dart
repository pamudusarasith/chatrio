import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _signedIn = false;

  SignInViewModel() {
    // Add listeners to reset states when user starts typing
    emailController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_errorMessage != null || _signedIn) {
      _errorMessage = null;
      _signedIn = false;
      notifyListeners();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;
  bool get signedIn => _signedIn;

  // Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    _signedIn = false;
    notifyListeners();
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  // Sign in method
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _signedIn = false;
    notifyListeners();

    try {
      // Sign in user with email and password
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _isLoading = false;
      _signedIn = true;
      notifyListeners();

      // Sign in successful - the navigation will be handled by the view
    } catch (e) {
      _isLoading = false;
      _signedIn = false;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No account found with this email address.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Too many failed attempts. Please try again later.';
            break;
          case 'invalid-credential':
            _errorMessage =
                'Invalid email or password. Please check your credentials.';
            break;
          default:
            _errorMessage = 'Sign in failed. Please try again.';
        }
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
      notifyListeners();
    }
  }

  // Reset password method
  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _errorMessage = 'Please enter your email address first.';
      notifyListeners();
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      _errorMessage = 'Password reset email sent to $email';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No account found with this email address.';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is not valid.';
            break;
          default:
            _errorMessage = 'Failed to send reset email. Please try again.';
        }
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.removeListener(_onFieldChanged);
    passwordController.removeListener(_onFieldChanged);

    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
