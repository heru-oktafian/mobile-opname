import 'package:flutter/material.dart';
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart'; // Pastikan path ini benar
import 'package:viopname/ui/pages/sign_in_page.dart';
import 'package:viopname/ui/widgets/branches_list.dart'; // Pastikan path ini benar
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk menggunakan jsonDecode dan jsonEncode
import 'package:viopname/shared/shared_methods.dart'; // Untuk showCustomSnackBar, pastikan path ini benar
import 'package:shared_preferences/shared_preferences.dart'; // Untuk SharedPreferences
import 'package:viopname/ui/pages/home_page.dart'; // Halaman tujuan setelah set branch berhasil
import 'package:viopname/shared/jwt_utils.dart';
import 'package:viopname/shared/auth_service.dart';

class BranchesPage extends StatefulWidget {
  final String? authToken; // Token yang diteruskan dari SignInPage

  const BranchesPage({super.key, this.authToken});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  List<dynamic> branches = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBranches(); // Panggil fungsi untuk mengambil data saat halaman dimuat
  }

  // Fungsi untuk mengambil daftar cabang dari API
  Future<void> _fetchBranches() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Bersihkan pesan error sebelumnya
    });

    final prefs = await SharedPreferences.getInstance();
    // Prioritaskan token dari SharedPreferences jika ada, jika tidak, gunakan dari widget.authToken
    // Ini penting jika pengguna kembali ke halaman ini setelah aplikasi ditutup,
    // atau jika token dari SharedPreferences lebih baru/valid.
    String? token = prefs.getString('jwt_token') ?? widget.authToken;

    if (token == null || token.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Token autentikasi tidak ditemukan. Silakan login ulang.';
      });
      // Gunakan addPostFrameCallback untuk menghindari setState selama build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, errorMessage, isError: true);
        // Mungkin arahkan kembali ke halaman login jika tidak ada token
        // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SignInPage()), (route) => false);
      });
      return;
    }

    // Cek expiry token
    try {
      if (isTokenExpired(token)) {
        await clearSessionAndGoToLogin(
          context,
          message: 'Sesi Anda telah kadaluarsa. Silakan login kembali.',
        );
        return;
      }
    } catch (e) {
      print('Error checking token expiry in branches page: $e');
    }

    final String apiUrl = '$baseUrl/list_branches'; // Ganti dengan URL API Anda

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            branches = responseData['data'];
            isLoading = false;
          });
          // showCustomSnackBar(context, responseData['message'] ?? 'Data cabang berhasil dimuat!'); // Opsional
        } else {
          setState(() {
            errorMessage =
                responseData['message'] ?? 'Gagal memuat data cabang.';
            isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackBar(context, errorMessage, isError: true);
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Error server: ${response.statusCode}. Coba lagi nanti.';
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackBar(context, errorMessage, isError: true);
        });
        print('Error response body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Terjadi kesalahan jaringan: $e. Periksa koneksi internet Anda.';
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, errorMessage, isError: true);
      });
      print('Exception fetching branches: $e');
    }
  }

  // Fungsi untuk mengatur cabang yang dipilih melalui API POST
  Future<void> _setBranch(String branchId) async {
    setState(() {
      isLoading = true; // Tampilkan loading saat proses set branch
    });

    final prefs = await SharedPreferences.getInstance();
    String? currentToken = prefs.getString(
      'jwt_token',
    ); // Ambil token yang tersimpan

    if (currentToken!.isEmpty) {
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(
          context,
          'Token autentikasi tidak ditemukan. Silakan login ulang.',
          isError: true,
        );
        // Kembali ke halaman login jika token tidak ada
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
        );
      });
      return;
    }

    final String apiUrl = '$baseUrl/set_branch'; // Ganti dengan URL API Anda
    final Map<String, String> body = {'branch_id': branchId};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization':
              'Bearer $currentToken', // Gunakan token yang ada saat ini
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          String newToken = responseData['data']; // Ambil token JWT yang BARU
          await prefs.setString(
            'jwt_token',
            newToken,
          ); // Simpan token baru, menimpa yang lama

          showCustomSnackBar(
            context,
            responseData['message'] ?? 'Cabang berhasil diatur!',
          );

          // Navigasi ke HomePage dan hapus semua rute sebelumnya
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HomePage(), // Pastikan HomePage diimpor
            ),
            (route) => false,
          );
        } else {
          showCustomSnackBar(
            context,
            responseData['message'] ??
                'Gagal mengatur cabang. Silakan coba lagi.',
            isError: true,
          );
          setState(() {
            isLoading = false;
          });
        }
      } else {
        showCustomSnackBar(
          context,
          'Error server saat mengatur cabang: ${response.statusCode}. Silakan coba lagi.',
          isError: true,
        );
        print('Error response body (set_branch): ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Terjadi kesalahan jaringan saat mengatur cabang: $e. Periksa koneksi internet Anda.',
        isError: true,
      );
      print('Exception setting branch: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Pilih Cabang',
          style: blackTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
        ),
        backgroundColor: AppColors.primary[100],
        elevation: 0,
      ),
      body: Center(
        child:
            isLoading // Tampilkan indikator loading jika sedang memuat data
            ? const CircularProgressIndicator()
            : errorMessage
                  .isNotEmpty // Tampilkan pesan error jika ada
            ? Text(
                errorMessage,
                style: blackTextStyle.copyWith(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              )
            : branches
                  .isEmpty // Tampilkan pesan jika tidak ada cabang
            ? Text(
                'Tidak ada cabang yang tersedia.',
                style: blackTextStyle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              )
            : ListView(
                // Tampilkan daftar cabang jika data tersedia
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  buildBranchesList(), // Membangun daftar BranchesList
                ],
              ),
      ),
    );
  }

  Widget buildBranchesList() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              // Map setiap data cabang ke widget BranchesList
              children: branches.map((branch) {
                return BranchesList(
                  iconUrl:
                      'assets/ic_branches.png', // Sesuaikan jika ikon dinamis
                  branchName:
                      branch['branch_name'] ?? 'Nama Cabang Tidak Diketahui',
                  branchId: branch['branch_id'] ?? 'ID Cabang Tidak Diketahui',
                  onTap: () {
                    // Panggil fungsi _setBranch saat BranchesList di-tap
                    _setBranch(branch['branch_id']);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
