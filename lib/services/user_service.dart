import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository = UserRepository();
  final _uuid = const Uuid();

  Future<User> getCurrentUser() async {
    User? currentUser = await _userRepository.getCurrentUser();

    if (currentUser != null) {
      // If user exists, return their ID
      return currentUser;
    }

    // Generate new unique user ID
    String newUserId = _uuid.v4();
    User newUser = User(
      id: newUserId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _userRepository.saveUser(newUser);
    return newUser;
  }
}
