import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http
import 'dart:convert'; // Import untuk menggunakan jsonEncode dan jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Opsional, untuk menyimpan token

import 'package:viopname/shared/shared_methods.dart'; // Asumsikan Anda punya file ini
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart'; // Asumsikan Anda punya file ini
import 'package:viopname/ui/pages/branches_page.dart'; // Halaman tujuan jika branch belum dipilih
import 'package:viopname/ui/pages/home_page.dart'; // Halaman tujuan akhir jika branch sudah ada di sesi
import 'package:viopname/shared/jwt_utils.dart';
import 'package:viopname/ui/widgets/buttons.dart'; // Asumsikan Anda punya widget CustomFilledButton
import 'package:viopname/ui/widgets/forms.dart'; // Asumsikan Anda punya widget CustomFormField

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Variabel untuk indikator loading
  bool isLoading = false;

  // Fungsi untuk pengecekan sesi login
  Future<void> checkLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      // Cek apakah token expired
      try {
        if (isTokenExpired(token)) {
          // Hapus token dan beri tahu user
          await prefs.remove('jwt_token');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackBar(
              context,
              'Sesi Anda telah kadaluarsa. Silakan login kembali.',
              isError: true,
            );
          });
          return;
        }
      } catch (e) {
        print('Error checking token expiry: $e');
      }
      // Jika token ada, coba decode payload untuk mencari branch_id
      try {
        final branchId = getBranchIdFromToken(token);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (branchId != null && branchId.isNotEmpty) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BranchesPage(authToken: token),
              ),
              (route) => false,
            );
          }
        });
        return;
      } catch (e) {
        print('Failed to decode saved token: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginSession();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Fungsi validasi input form
  bool validate() {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }
    return true;
  }

  // Fungsi untuk melakukan request login ke API
  Future<void> login() async {
    // Validasi input sebelum mengirim request
    if (!validate()) {
      showCustomSnackBar(
        context,
        'Username dan password harus diisi',
        isError: true, // Menandakan pesan error
      );
      return;
    }

    setState(() {
      isLoading = true; // Set loading menjadi true saat proses login dimulai
    });

    // Ganti dengan endpoint API login Anda yang sebenarnya
    final String apiUrl = '$baseUrl/login';
    final Map<String, String> body = {
      'username': usernameController.text,
      'password': passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Login berhasil
          String token = responseData['data']; // Ambil token JWT dari response

          // Opsional: Simpan token secara persisten menggunakan shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          print('Token JWT disimpan: $token'); // Untuk debugging

          showCustomSnackBar(
            context,
            responseData['message'] ?? 'Login berhasil!',
          );

          // Setelah login berhasil, cek apakah token berisi branch_id.
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              String payload = parts[1];
              String normalized = payload
                  .replaceAll('-', '+')
                  .replaceAll('_', '/');
              switch (normalized.length % 4) {
                case 2:
                  normalized += '==';
                  break;
                case 3:
                  normalized += '=';
                  break;
              }

              final decoded = utf8.decode(base64Url.decode(normalized));
              final Map<String, dynamic> payloadData = jsonDecode(decoded);
              final String? branchId = payloadData['branch_id']?.toString();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (branchId != null && branchId.isNotEmpty) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BranchesPage(authToken: token),
                    ),
                    (route) => false,
                  );
                }
              });
            } else {
              // Fallback: jika token tidak memiliki format JWT, arahkan ke BranchesPage
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BranchesPage(authToken: token),
                  ),
                  (route) => false,
                );
              });
            }
          } catch (e) {
            print('Error decoding token after login: $e');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => BranchesPage(authToken: token),
                ),
                (route) => false,
              );
            });
          }
        } else {
          // Login gagal dari sisi server (misal: username/password salah, user tidak aktif)
          showCustomSnackBar(
            context,
            responseData['message'] ?? 'Login gagal. Silakan coba lagi.',
            isError: true, // Menandakan pesan error
          );
        }
      } else {
        // Respon server tidak 200 OK (misal: 401 Unauthorized, 500 Internal Server Error)
        showCustomSnackBar(
          context,
          'Terjadi kesalahan server: ${response.statusCode}. Silakan coba lagi.',
          isError: true, // Menandakan pesan error
        );
        print('Error response status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
      }
    } catch (e) {
      // Terjadi error pada koneksi atau parsing data (misal: tidak ada internet)
      showCustomSnackBar(
        context,
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        isError: true, // Menandakan pesan error
      );
      print('Exception during login: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading menjadi false setelah proses selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.secondary[100], // Menggunakan warna dari theme.dart
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Container(
            height: 75,
            margin: const EdgeInsets.only(top: 75, bottom: 100),
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/img_logo.png')),
            ),
          ),
          Text(
            'Sign In &\nOpname Your Product Stocks.',
            style: blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: semiBold,
            ), // Menggunakan style dari theme.dart
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Username
                CustomFormField(
                  title: 'Username',
                  hintText: 'input your username',
                  obscureText: false,
                  controller: usernameController,
                ),
                const SizedBox(height: 16),
                // Input Password
                CustomFormField(
                  title: 'Password',
                  hintText: '******',
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 30),
                // Tombol Sign In
                CustomFilledButton(
                  title: isLoading
                      ? 'Loading...'
                      : 'Sign In', // Tampilkan teks loading saat proses
                  height: 50,
                  onPressed: isLoading
                      ? null
                      : login, // Nonaktifkan tombol saat loading
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
