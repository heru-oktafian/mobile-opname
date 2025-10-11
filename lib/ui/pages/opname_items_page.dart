// lib/ui/pages/opname_items_page.dart

import 'package:flutter/material.dart';
import 'package:viopname/shared/shared_values.dart';
import 'package:viopname/shared/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viopname/shared/shared_methods.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Tambahkan ini jika sebelumnya tidak ada untuk Timer

class OpnameItemsPage extends StatefulWidget {
  final String opnameId;
  final String opnameDescription;
  final String opnameStatus;

  const OpnameItemsPage({
    super.key,
    required this.opnameId,
    this.opnameDescription = 'Detail Item Opname',
    this.opnameStatus = 'active',
  });

  @override
  State<OpnameItemsPage> createState() => _OpnameItemsPageState();
}

class _OpnameItemsPageState extends State<OpnameItemsPage> {
  List<dynamic> _opnameItems = [];
  // Cache untuk produk yang sudah pernah di-load, keyed by pro_id for fast lookup
  final Map<String, dynamic> _productCache = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSaving = false;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  DateTime? _selectedExpiredDate;
  Map<String, dynamic>? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _fetchOpnameItems();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _setErrorMessageAndShowSnackbar(String message, {bool isError = true}) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCustomSnackBar(context, message, isError: isError);
    });
  }

  Future<void> _fetchOpnameItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      _setErrorMessageAndShowSnackbar(
        'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
      return;
    }

    final String apiUrl = '$baseUrl/opname-items/${widget.opnameId}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final dynamic data = responseData['data'];
          if (data is List) {
            setState(() {
              _opnameItems = data;
              _isLoading = false;
            });
          } else {
            _setErrorMessageAndShowSnackbar(
              'Belum ada item opname yang tersimpan.',
            );
          }
        } else {
          _setErrorMessageAndShowSnackbar(
            responseData['message'] ?? 'Gagal memuat item opname.',
          );
        }
      } else {
        _setErrorMessageAndShowSnackbar(
          'Error server: ${response.statusCode}. Coba lagi nanti.',
        );
        print('Error response body (opname_items_all): ${response.body}');
      }
    } catch (e) {
      _setErrorMessageAndShowSnackbar(
        'Terjadi kesalahan jaringan: $e. Periksa koneksi internet Anda.',
      );
      print('Exception fetching opname items: $e');
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    StateSetter setStateDialog,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiredDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.gray,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExpiredDate) {
      setStateDialog(() {
        _selectedExpiredDate = picked;
      });
    }
  }

  Future<Map<String, dynamic>?> _showProductSearchDialog(
    BuildContext context,
  ) async {
    List<dynamic> products = [];
    bool isLoadingProducts = true;
    String productSearchError = '';
    bool hasFetchedInitialProducts = false;
    TextEditingController dialogSearchController = TextEditingController();
    Timer? debounce;

    Future<void> fetchProducts(
      String searchQuery,
      StateSetter setStateDialogProductPicker,
    ) async {
      // Cek cache dulu: jika ada data produk di cache, filter dan gunakan
      if (_productCache.isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final cachedMatches = query.isEmpty
            ? _productCache.values.toList()
            : _productCache.values.where((p) {
                final name = (p['pro_name'] ?? '').toString().toLowerCase();
                final id = (p['pro_id'] ?? '').toString().toLowerCase();
                return name.contains(query) || id.contains(query);
              }).toList();

        if (cachedMatches.isNotEmpty) {
          setStateDialogProductPicker(() {
            isLoadingProducts = false;
            productSearchError = '';
            products = cachedMatches;
          });
          return; // tidak perlu memanggil API
        }
      }

      setStateDialogProductPicker(() {
        isLoadingProducts = true;
        productSearchError = '';
        products = [];
      });

      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setStateDialogProductPicker(() {
          productSearchError = 'Token autentikasi tidak ditemukan.';
          isLoadingProducts = false;
        });
        return;
      }

      final String apiUrl = '$baseUrl/cmb-product-opname?search=$searchQuery';

      try {
        // Menggunakan GET dan mengirim 'search' sebagai header
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
            final dynamic data = responseData['data'];
            if (data is List) {
              setStateDialogProductPicker(() {
                products = data;
                isLoadingProducts = false;
              });
              // Gabungkan hasil API ke cache produk untuk pencarian berikutnya
              try {
                final List<dynamic> apiList = List<dynamic>.from(
                  responseData['data'],
                );
                for (final item in apiList) {
                  final id = item['pro_id']?.toString();
                  if (id != null && id.isNotEmpty) {
                    if (!_productCache.containsKey(id)) {
                      _productCache[id] = item;
                    }
                  }
                }
              } catch (_) {
                // jika struktur data tidak sesuai, abaikan cache merge
              }
            } else {
              setStateDialogProductPicker(() {
                productSearchError = 'Data produk tidak valid.';
                isLoadingProducts = false;
              });
            }
          } else {
            setStateDialogProductPicker(() {
              productSearchError = 'Tidak ada item yang tersimpan.';
              isLoadingProducts = false;
            });
          }
        } else {
          setStateDialogProductPicker(() {
            productSearchError = 'Error server: ${response.statusCode}. ';
            if (response.body.isNotEmpty) {
              try {
                final errorResponse = jsonDecode(response.body);
                productSearchError +=
                    errorResponse['message'] ?? 'Respon error tidak diketahui.';
              } catch (e) {
                productSearchError += 'Respon tidak dapat diurai.';
              }
            }
            isLoadingProducts = false;
          });
          print('Error response body ($apiUrl): ${response.body}');
        }
      } catch (e) {
        setStateDialogProductPicker(() {
          productSearchError = 'Kesalahan jaringan: $e.';
          isLoadingProducts = false;
        });
        print('Exception fetching products: $e');
      }
    }

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialogProductPicker) {
            if (!hasFetchedInitialProducts) {
              hasFetchedInitialProducts = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  // Tambahkan pengecekan mounted
                  fetchProducts('', setStateDialogProductPicker);
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Pilih Produk',
                style: blackTextStyle.copyWith(fontWeight: semiBold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dialogSearchController,
                      decoration: InputDecoration(
                        labelText: 'Cari Produk...',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search, color: AppColors.primary),
                          onPressed: () {
                            if (debounce?.isActive ?? false) {
                              debounce?.cancel();
                            }
                            fetchProducts(
                              dialogSearchController.text,
                              setStateDialogProductPicker,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppColors.gray[200],
                      ),
                      style: blackTextStyle,
                      onChanged: (value) {
                        if (debounce?.isActive ?? false) debounce?.cancel();
                        debounce = Timer(const Duration(milliseconds: 500), () {
                          fetchProducts(value, setStateDialogProductPicker);
                        });
                      },
                      onSubmitted: (value) {
                        if (debounce?.isActive ?? false) debounce?.cancel();
                        fetchProducts(value, setStateDialogProductPicker);
                      },
                    ),
                    const SizedBox(height: 15),
                    isLoadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : productSearchError.isNotEmpty
                        ? Text(
                            productSearchError,
                            style: greyTextStyle.copyWith(color: Colors.red),
                          )
                        : products.isEmpty
                        ? Text(
                            dialogSearchController.text.isNotEmpty
                                ? 'Tidak ada produk ditemukan untuk "${dialogSearchController.text}".'
                                : 'Tidak ada produk tersedia.',
                            style: greyTextStyle,
                            textAlign: TextAlign.center,
                          )
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ListTile(
                                  title: Text(
                                    product['pro_name'] ?? 'Nama Produk',
                                    style: blackTextStyle,
                                  ),
                                  subtitle: Text(
                                    'ID: ${product['pro_id'] ?? 'N/A'} - Stok: ${product['stock'] ?? 'N/A'} ${product['unit_name'] ?? ''}',
                                    style: greyTextStyle,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop(product);
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Batal',
                    style: blackTextStyle.copyWith(color: AppColors.gray),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitItem(BuildContext dialogContext) async {
    if (_selectedProduct == null) {
      showCustomSnackBar(
        context,
        'Pilih Produk terlebih dahulu!',
        isError: true,
      );
      return;
    }

    if (_qtyController.text.isEmpty || _selectedExpiredDate == null) {
      showCustomSnackBar(
        context,
        'Kuantitas dan Tanggal Kadaluarsa harus diisi!',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      _setErrorMessageAndShowSnackbar('Token tidak ditemukan, login ulang.');
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final String formattedExpiredDate = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedExpiredDate!);

    final String apiUrl = '$baseUrl/opname-items';

    final Map<String, dynamic> body = {
      "opname_id": widget.opnameId,
      "product_id": _selectedProduct!['pro_id'],
      "qty": int.parse(_qtyController.text),
      "expired_date": formattedExpiredDate,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final status = responseData['status']?.toString().toLowerCase();

        if (status == 'success') {
          // Tutup dialog dulu
          Navigator.of(dialogContext).pop();

          // Tampilkan snackbar dan refresh
          showCustomSnackBar(
            context,
            responseData['message'] ?? 'Item berhasil disimpan.',
          );

          _clearFormFields();
          _fetchOpnameItems(); // Refresh page
        } else {
          showCustomSnackBar(
            context,
            responseData['message'] ?? 'Gagal menyimpan item.',
            isError: true,
          );
        }
      } else {
        showCustomSnackBar(
          context,
          'Error ${response.statusCode}: ${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Terjadi kesalahan jaringan: $e',
        isError: true,
      );
      print('SubmitItem error: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _clearFormFields() {
    _productNameController.clear();
    _qtyController.clear();
    setState(() {
      _selectedExpiredDate = null;
      _selectedProduct = null;
    });
  }

  // Hapus parameter itemToEdit
  void _showAddItemDialog() {
    _clearFormFields(); // Selalu bersihkan field karena hanya mode tambah baru

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Tambah Item Baru', // Hanya 'Tambah Item Baru'
                style: blackTextStyle.copyWith(fontWeight: semiBold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        final selected = await _showProductSearchDialog(
                          context,
                        );
                        if (selected != null) {
                          setStateDialog(() {
                            _selectedProduct = selected;
                            _productNameController.text =
                                _selectedProduct!['pro_name'];
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _productNameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: _selectedProduct == null
                                ? 'Pilih Produk'
                                : _selectedProduct!['pro_name'],
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.gray[200],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.success,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: blackTextStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.success,
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: AppColors.gray[200],
                      ),
                      style: blackTextStyle,
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        await _selectDate(context, setStateDialog);
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: _selectedExpiredDate == null
                                ? 'Expired Date'
                                : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedExpiredDate!),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.gray[200],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.success,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          readOnly: true,
                          style: blackTextStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Batal',
                    style: blackTextStyle.copyWith(color: AppColors.gray),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          _submitItem(context); // Panggil tanpa parameter
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Tambah', // Hanya 'Tambah'
                          style: whiteTextStyle.copyWith(fontWeight: medium),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    // Tombol edit dihapus dari sini
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['product_name'] ?? 'Nama Produk Tidak Diketahui',
                  style: blackTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: semiBold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga:', style: greyTextStyle.copyWith(fontSize: 12)),
                    Text(
                      item['price'] ?? 'N/A',
                      style: blackTextStyle.copyWith(fontWeight: medium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty:', style: greyTextStyle.copyWith(fontSize: 12)),
                    Text(
                      '${item['qty'] ?? 'N/A'}',
                      style: blackTextStyle.copyWith(fontWeight: medium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qty Exist:',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      '${item['qty_exist'] ?? 'N/A'}',
                      style: blackTextStyle.copyWith(fontWeight: medium),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub Total:',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      item['sub_total'] ?? 'N/A',
                      style: blackTextStyle.copyWith(
                        fontWeight: semiBold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub Total Exist:',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                    Text(
                      item['sub_total_exist'] ?? 'N/A',
                      style: blackTextStyle.copyWith(
                        fontWeight: semiBold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item['expired_date'] != null && item['expired_date'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Expired: ${item['expired_date']}',
                style: greyTextStyle.copyWith(
                  fontSize: 12,
                  color: AppColors.error,
                ),
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
          widget.opnameDescription,
          style: blackTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.gray),
          onPressed: () {
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
            : _opnameItems.isEmpty
            ? Text(
                'Tidak ada item untuk opname ini.',
                style: blackTextStyle.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: _opnameItems.map((item) {
                  return _buildItemCard(item);
                }).toList(),
              ),
      ),
      floatingActionButton: widget.opnameStatus == 'active'
          ? FloatingActionButton(
              onPressed: () {
                _showAddItemDialog();
              },
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
