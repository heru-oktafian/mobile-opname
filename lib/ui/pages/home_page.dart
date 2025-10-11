// lib/ui/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart';
import 'package:viopname/ui/pages/profile_page.dart';
import 'package:viopname/ui/widgets/home_latest_opnames.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/ui/pages/sign_in_page.dart';
import 'package:viopname/shared/shared_methods.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:viopname/shared/jwt_utils.dart';
import 'package:viopname/shared/auth_service.dart';
import 'package:viopname/ui/pages/opnames_page.dart'; // Import OpnamePages

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Pengguna';
  String _userRole = '';
  List<dynamic> _latestOpnames = [];
  bool _isLoadingOpnames = true;
  String _opnamesErrorMessage = '';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchLatestOpnames();
  }

  // Fungsi untuk memuat data pengguna (nama dan peran) dari token JWT
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token != null && token.isNotEmpty) {
      try {
        // Jika token expired maka logout menggunakan helper terpusat
        if (isTokenExpired(token)) {
          await clearSessionAndGoToLogin(
            context,
            message: 'Sesi Anda telah kadaluarsa. Silakan login kembali.',
          );
          return;
        }
        final name = getNameFromToken(token);
        final role = getUserRoleFromToken(token);

        setState(() {
          _userName = name ?? 'Pengguna';
          _userRole = role ?? '';
        });
      } catch (e) {
        print('Error decoding token or loading user data: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackBar(
            context,
            'Gagal memuat data pengguna. Token tidak valid.',
            isError: true,
          );
        });
        _logout();
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logout();
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    try {
      if (token != null && token.isNotEmpty) {
        final String apiUrl = '$baseUrl/logout';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCustomSnackBar(
                context,
                responseData['message'] ?? 'Logout berhasil!',
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCustomSnackBar(
                context,
                responseData['message'] ?? 'Terjadi masalah saat logout.',
                isError: true,
              );
            });
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackBar(
              context,
              'Error server saat logout: ${response.statusCode}.',
              isError: true,
            );
          });
          print('Error response body (logout): ${response.body}');
        }
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(
          context,
          'Terjadi kesalahan jaringan saat logout: $e.',
          isError: true,
        );
      });
      print('Exception during logout API call: $e');
    } finally {
      await prefs.remove('jwt_token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchLatestOpnames() async {
    setState(() {
      _isLoadingOpnames = true;
      _opnamesErrorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingOpnames = false;
        _opnamesErrorMessage =
            'Token autentikasi tidak ditemukan untuk mengambil data opname.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, _opnamesErrorMessage, isError: true);
      });
      return;
    }

    final String apiUrl = '$baseUrl/mobile-opnames';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // --- PERBAIKAN DARI SINI ---
          final dynamic data = responseData['data'];
          // Pengecekan apakah data adalah List dan tidak null
          if (data is List) {
            setState(() {
              _latestOpnames = data; // Tetapkan data jika merupakan List
              _isLoadingOpnames = false;
            });
          } else {
            // Tangani kasus di mana 'data' null atau bukan List
            setState(() {
              _opnamesErrorMessage = 'Belum ada Opname terbaru.';
              _latestOpnames = []; // Tetapkan list kosong sebagai default
              _isLoadingOpnames = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCustomSnackBar(context, _opnamesErrorMessage, isError: true);
            });
          }
        }
        // --- SAMPAI SINI ---
      } else {
        setState(() {
          _opnamesErrorMessage =
              'Error server: ${response.statusCode}. Coba lagi nanti.';
          _isLoadingOpnames = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackBar(context, _opnamesErrorMessage, isError: true);
        });
        print('Error response body (mobile_opnames): ${response.body}');
      }
    } catch (e) {
      setState(() {
        _opnamesErrorMessage =
            'Terjadi kesalahan jaringan: $e. Periksa koneksi internet Anda.';
        _isLoadingOpnames = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackBar(context, _opnamesErrorMessage, isError: true);
      });
      print('Exception fetching latest opnames: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary[100],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        padding: const EdgeInsets.all(0),
        height: 56,
        shape: const CircularNotchedRectangle(),
        clipBehavior: Clip.antiAlias,
        notchMargin: 6,
        elevation: 0,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.black,
          selectedLabelStyle: blackTextStyle.copyWith(
            color: AppColors.primary,
            fontWeight: medium,
            fontSize: 10,
          ),
          unselectedLabelStyle: blackTextStyle.copyWith(
            color: Colors.black,
            fontWeight: medium,
            fontSize: 10,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: (index) async {
            // Tambahkan async di sini
            setState(() {
              _selectedIndex = index;
            });
            if (index == 0) {
              // Already on Home, maybe refresh?
              _fetchLatestOpnames();
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            } else if (index == 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showCustomSnackBar(
                  context,
                  'Halaman Report Opnames belum diimplementasikan.',
                );
              });
            } else if (index == 3) {
              _logout();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/ic_home.png',
                width: 20,
                height: 20,
                color: _selectedIndex == 0 ? AppColors.primary : Colors.black,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/ic_edit_profile.png',
                width: 20,
                height: 20,
                color: _selectedIndex == 1 ? AppColors.primary : Colors.black,
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/ic_pie_chart.png',
                width: 20,
                height: 20,
                color: _selectedIndex == 2 ? AppColors.primary : Colors.black,
              ),
              label: 'Opnames',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/ic_logout.png',
                width: 20,
                height: 20,
                color: _selectedIndex == 3 ? AppColors.primary : Colors.black,
              ),
              label: 'Logout',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.primary, width: 1),
        ),
        child: Image.asset('assets/ic_plus_circle.png', width: 24),
        onPressed: () async {
          // Tambahkan async di sini
          // === PERUBAHAN DI SINI: Ketika menavigasi ke Opnames (FAB) ===
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OpnamePages()),
          );
          if (shouldRefresh == true) {
            _fetchLatestOpnames();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [buildProfile(context), buildLatestOpname()],
      ),
    );
  }

  Widget buildProfile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hey,', style: greyTextStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                // Menggunakan _userName dari state yang diambil dari token
                _userName,
                style: blackTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: semiBold,
                ),
              ),
              // Tambahkan tampilan peran pengguna jika diperlukan
              _userRole.isNotEmpty
                  ? Text(_userRole, style: greyTextStyle.copyWith(fontSize: 12))
                  : const SizedBox.shrink(),
            ],
          ),
          GestureDetector(
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showCustomSnackBar(
                  context,
                  'Halaman Profile belum diimplementasikan.',
                );
              });
            },
            child: Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/img_usr_profile.png'),
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary[100],
                  ),
                  child: Center(
                    child: Icon(Icons.check_circle, color: AppColors.success),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLatestOpname() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Opnames',
            style: blackTextStyle.copyWith(fontSize: 16, fontWeight: semiBold),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.gray[100],
            ),
            child: _isLoadingOpnames
                ? const Center(child: CircularProgressIndicator())
                : _opnamesErrorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _opnamesErrorMessage,
                      style: greyTextStyle.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _latestOpnames.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data opname terbaru.',
                      style: greyTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: _latestOpnames.map((opname) {
                      return HomeLatestOpnames(
                        iconUrl: 'assets/ic_opname_color.png',
                        description:
                            opname['description'] ??
                            'Deskripsi Tidak Diketahui',
                        opnameDate:
                            opname['opname_date'] ?? 'Tanggal Tidak Diketahui',
                        totalOpname:
                            opname['total_opname'] ?? 'Nilai Tidak Diketahui',
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
