import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController =
      TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;
  String? _errorMessage;
  bool _accountCreated = false;

  CreateAccountViewModel() {
    // Add listeners to reset states when user starts typing
    fullNameController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    retypePasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_errorMessage != null || _accountCreated) {
      _errorMessage = null;
      _accountCreated = false;
      notifyListeners();
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureRetypePassword => _obscureRetypePassword;
  String? get errorMessage => _errorMessage;
  bool get accountCreated => _accountCreated;

  // Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleRetypePasswordVisibility() {
    _obscureRetypePassword = !_obscureRetypePassword;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    _accountCreated = false;
    notifyListeners();
  }

  // Validation methods
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

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
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateRetypePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please retype your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Create account method
  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _accountCreated = false;
    notifyListeners();

    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      // Update user display name
      await userCredential.user?.updateDisplayName(
        fullNameController.text.trim(),
      );

      _isLoading = false;
      _accountCreated = true;
      notifyListeners();

      // Account created successfully - the navigation will be handled by the view
    } catch (e) {
      _isLoading = false;
      _accountCreated = false;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            _errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is not valid.';
            break;
          default:
            _errorMessage = 'An error occurred. Please try again.';
        }
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.removeListener(_onFieldChanged);
    emailController.removeListener(_onFieldChanged);
    passwordController.removeListener(_onFieldChanged);
    retypePasswordController.removeListener(_onFieldChanged);

    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    retypePasswordController.dispose();
    super.dispose();
  }
}
