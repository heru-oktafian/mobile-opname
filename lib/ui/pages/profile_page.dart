import 'package:flutter/material.dart';
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart'; // Pastikan path ini benar
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/shared/shared_methods.dart'; // Untuk showCustomSnackBar

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _profileData = {}; // Untuk menyimpan data profil
  bool _isLoading = true; // Status loading
  String _errorMessage = ''; // Pesan error
  String _headerMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileData(); // Panggil fungsi untuk mengambil data saat halaman dimuat
  }

  // Fungsi untuk mengambil data profil dari API
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Bersihkan pesan error sebelumnya
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Token autentikasi tidak ditemukan. Silakan login ulang.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, _errorMessage, isError: true);
        // Mungkin arahkan kembali ke halaman login jika tidak ada token
        // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SignInPage()), (route) => false);
      });
      return;
    }

    final String apiUrl = '$baseUrl/profile'; // URL API Profil Anda

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Opsional, tapi aman untuk GET
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _profileData = responseData['data'];
            _isLoading = false;
            _headerMessage = responseData['message'];
          });
          // showCustomSnackBar(context, responseData['message'] ?? 'Data profil berhasil dimuat!'); // Opsional
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Gagal memuat data profil.';
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackBar(context, _errorMessage, isError: true);
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error server: ${response.statusCode}. Coba lagi nanti.';
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackBar(context, _errorMessage, isError: true);
        });
        print('Error response body (profile): ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan jaringan: $e. Periksa koneksi internet Anda.';
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, _errorMessage, isError: true);
      });
      print('Exception fetching profile data: $e');
    }
  }

  // Widget pembantu untuk menampilkan item informasi
  Widget _buildInfoItem(String title, String? value, {bool isLarge = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); // Jangan tampilkan jika nilai kosong
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: greyTextStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: blackTextStyle.copyWith(
              fontSize: isLarge ? 18 : 16,
              fontWeight: isLarge ? semiBold : reguler,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Profil Saya',
          style: blackTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
        ),
        backgroundColor: AppColors.primary[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gray), // Ikon kembali
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child:
            _isLoading // Tampilkan indikator loading
            ? const CircularProgressIndicator()
            : _errorMessage
                  .isNotEmpty // Tampilkan pesan error
            ? Text(
                _errorMessage,
                style: blackTextStyle.copyWith(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
                  // Bagian Foto Profil dan Nama
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/img_usr_profile.png',
                            ), // Ganti dengan foto profil dinamis jika ada
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _profileData['profile_name'] ?? 'Nama Pengguna',
                        style: blackTextStyle.copyWith(
                          fontSize: 24,
                          fontWeight: bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        // Otoritas atau role bisa diambil dari message atau jika ada di data payload
                        _headerMessage ?? 'Opname User',
                        style: greyTextStyle.copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                  // Bagian Informasi Umum
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Umum',
                          style: blackTextStyle.copyWith(
                            fontSize: 18,
                            fontWeight: semiBold,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        _buildInfoItem(
                          'Nama Lengkap',
                          _profileData['profile_name'],
                        ),
                        _buildInfoItem('Email', _profileData['email']),
                        _buildInfoItem('Telepon', _profileData['phone']),
                        _buildInfoItem('Alamat', _profileData['address']),
                        _buildInfoItem('Cabang', _profileData['branch_name']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bagian Informasi Lisensi & Legalitas
                  // Container(
                  //   padding: const EdgeInsets.all(22),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(20),
                  //     color: Colors.white,
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.grey.withOpacity(0.1),
                  //         spreadRadius: 1,
                  //         blurRadius: 5,
                  //         offset: const Offset(0, 3),
                  //       ),
                  //     ],
                  //   ),
                  // child: Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       'Lisensi & Legalitas',
                  //       style: blackTextStyle.copyWith(
                  //         fontSize: 18,
                  //         fontWeight: semiBold,
                  //       ),
                  //     ),
                  //     const Divider(height: 20, thickness: 1),
                  //     _buildInfoItem('Nomor SIA', _profileData['sia_id']),
                  //     _buildInfoItem('Nama SIA', _profileData['sia_name']),
                  //     _buildInfoItem('Nomor PSA', _profileData['psa_id']),
                  //     _buildInfoItem('Nama PSA', _profileData['psa_name']),
                  //     _buildInfoItem('Nomor SIPA', _profileData['sipa']),
                  //     _buildInfoItem('Nama SIPA', _profileData['sipa_name']),
                  //     // Anda bisa menambahkan aping_id, bank_name, dll. jika ingin ditampilkan
                  //     // _buildInfoItem('ID Aping', _profileData['aping_id']),
                  //     // _buildInfoItem('Nama Bank', _profileData['bank_name']),
                  //   ],
                  // ),
                  // ),
                  // const SizedBox(height: 20),

                  // Bagian Preferensi & Lain-lain
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferensi',
                          style: blackTextStyle.copyWith(
                            fontSize: 18,
                            fontWeight: semiBold,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        _buildInfoItem(
                          'Persentase Pajak',
                          _profileData['tax_percentage']?.toString(),
                        ),
                        _buildInfoItem(
                          'Metode Jurnal',
                          _profileData['journal_method'],
                        ),
                        _buildInfoItem(
                          'Member Default',
                          _profileData['default_member'],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), // Spasi di bagian bawah
                ],
              ),
      ),
    );
  }
}
