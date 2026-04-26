import 'package:velotolouse/model/user/user.dart';

class UserDto {
  static User fromRtdb(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }

  static Map<String, dynamic> toRtdb(User user) {
    return {
      'name': user.name,
      'email': user.email,
      'password': user.password,
    };
  }
}