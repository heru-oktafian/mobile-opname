part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLogin extends AuthEvent {
  final SignInFormModel signInFormModel;
  const AuthLogin({required this.signInFormModel});
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}
