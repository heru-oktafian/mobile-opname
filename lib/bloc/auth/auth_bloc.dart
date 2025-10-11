import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:viopname/models/sign_in_form_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) {
      // TODO: implement event handler
      if (event is AuthLogin) {
        emit(AuthLoading());
        emit(AuthLoginSuccess());
      } else if (event is AuthLogout) {
        emit(AuthLoading());
        emit(AuthInitial());
      }
    });
  }
}
