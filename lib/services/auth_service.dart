import 'package:http/http.dart' as http;
import 'package:viopname/models/sign_in_form_model.dart';
import 'package:viopname/shared/shared_values.dart';

class AuthService {
  Future<bool> LoginIn(SignInFormModel signInFormModel) async {
    var url = Uri.parse('$baseUrl/login');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: signInFormModel.toJson(),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
