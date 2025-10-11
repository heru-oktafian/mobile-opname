class SignInFormModel {
  final String username;
  final String password;

  SignInFormModel({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}
