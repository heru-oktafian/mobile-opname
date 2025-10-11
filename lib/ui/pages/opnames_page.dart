// lib/ui/pages/opname_page.dart

import 'package:flutter/material.dart';
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart';
import 'package:viopname/ui/widgets/home_latest_opnames.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/shared/shared_methods.dart';
import 'package:viopname/ui/pages/opname_items_page.dart';

class OpnamePages extends StatefulWidget {
  const OpnamePages({super.key});

  @override
  State<OpnamePages> createState() => _OpnamePagesState();
}

class _OpnamePagesState extends State<OpnamePages> {
  List<dynamic> _activeOpnames = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchActiveOpnames();
  }

  Future<void> _fetchActiveOpnames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
      });
      return;
    }

    final String apiUrl = '$baseUrl/mobile-opnames-active';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Jika data valid, tampilkan produk
          final dynamic data = responseData['data'];

          // Pastikan data adalah List sebelum menetapkannya ke _activeOpnames
          if (data is List) {
            setState(() {
              _activeOpnames = data;
              _isLoading = false;
            });
          } else {
            // Tangani kasus di mana 'data' null atau bukan List
            setState(() {
              _errorMessage = 'Tidak ada Opname yang aktif.';
              _activeOpnames = []; // Tetapkan list kosong sebagai default
              _isLoading = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showCustomSnackBar(context, _errorMessage, isError: true);
            });
          }
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
        print('Error response body (mobile_opname_actives): ${response.body}');
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
      print('Exception fetching active opnames: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Pilih Opname',
          style: blackTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
        ),
        backgroundColor: AppColors.primary[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gray),
          onPressed: () {
            // Ketika kembali dari OpnamePages ke HomePage,
            // beri tahu HomePage untuk refresh jika perlu
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage.isNotEmpty
            ? Text(
                _errorMessage,
                style: blackTextStyle.copyWith(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              )
            : _activeOpnames.isEmpty
            ? Text(
                'Tidak ada opname aktif yang tersedia.',
                style: blackTextStyle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: _activeOpnames.map((opname) {
                  return HomeLatestOpnames(
                    iconUrl: 'assets/ic_opname_color.png',
                    description:
                        opname['description'] ?? 'Deskripsi Tidak Diketahui',
                    opnameDate:
                        opname['opname_date'] ?? 'Tanggal Tidak Diketahui',
                    totalOpname:
                        opname['total_opname'] ?? 'Nilai Tidak Diketahui',
                    opnameId: opname['id'],
                    onTap: () async {
                      // === PERUBAHAN DI SINI ===
                      final bool? shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpnameItemsPage(
                            opnameId: opname['id'],
                            opnameDescription:
                                opname['description'] ?? 'Detail Opname',
                            opnameStatus:
                                opname['status'] ??
                                'active', // === Asumsi opname status ada di sini ===
                          ),
                        ),
                      );
                      // Jika kembali dan shouldRefresh adalah true, maka refresh data opname aktif
                      if (shouldRefresh == true) {
                        _fetchActiveOpnames();
                      }
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }
}
