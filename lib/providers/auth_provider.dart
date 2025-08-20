import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        _currentUser = await DatabaseService.getUserById(userId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For demo purposes, we'll check if user exists or create a teacher account
      UserModel? user = await DatabaseService.getUserByEmail(email);
      
      if (user == null) {
        // Create a new teacher account
        user = UserModel(
          name: email.split('@').first.replaceAll('.', ' ').split(' ')
              .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
              .join(' '),
          email: email,
          role: UserRole.teacher,
          preferredLanguage: 'zopau',
        );
        await DatabaseService.saveUser(user);
      }

      _currentUser = user;
      
      // Save user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    
    notifyListeners();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    try {
      await DatabaseService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Initialize with demo teacher user for testing
  Future<void> initializeWithDemoUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if demo user already exists
      const demoEmail = 'teacher@example.com';
      UserModel? user = await DatabaseService.getUserByEmail(demoEmail);

      if (user == null) {
        // Create demo teacher user
        user = UserModel(
          name: 'Teacher Demo',
          email: demoEmail,
          role: UserRole.teacher,
          phoneNumber: '+1-555-0123',
          preferredLanguage: 'en',
        );

        await DatabaseService.saveUser(user);
      }

      _currentUser = user;

      // Save user ID to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}