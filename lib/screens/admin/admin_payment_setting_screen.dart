import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/payment_setting.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../utils/feedback.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_widget.dart';

/// Admin: atur satu QR pembayaran global + rekening tujuan.
class AdminPaymentSettingScreen extends StatefulWidget {
  const AdminPaymentSettingScreen({super.key});

  @override
  State<AdminPaymentSettingScreen> createState() =>
      _AdminPaymentSettingScreenState();
}

class _AdminPaymentSettingScreenState extends State<AdminPaymentSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentSetting? _setting;
  XFile? _pickedQr;
  Uint8List? _pickedBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _adminPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final setting = await PaymentService.getSetting();

      if (!mounted) {
        return;
      }

      setState(() {
        _setting = setting;
        _accountNameController.text = setting.accountName ?? '';
        _accountNumberController.text = setting.accountNumber ?? '';
        _adminPhoneController.text = setting.adminPhone ?? '';
        _notesController.text = setting.notes ?? '';
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _pickQr() async {
    XFile? picked;

    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 90,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'Tidak dapat membuka galeri. Coba lagi.',
        isError: true,
      );
      return;
    }

    if (picked == null || !mounted) {
      return;
    }

    final bytes = await picked.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _pickedQr = picked;
      _pickedBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final setting = await PaymentService.updateSetting(
        qr: _pickedQr,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        adminPhone: _adminPhoneController.text,
        notes: _notesController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _setting = setting;
        _pickedQr = null;
        _pickedBytes = null;
        _isSaving = false;
      });

      showAppSnackBar(
        context,
        'Pengaturan pembayaran berhasil disimpan.',
        isSuccess: true,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      showAppSnackBar(
        context,
        error.firstValidationError ?? error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      showAppSnackBar(
        context,
        'Gagal menyimpan pengaturan. Coba lagi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Pembayaran')),
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: 'Memuat pengaturan...')
            : _errorMessage != null
            ? ErrorState(message: _errorMessage!, onRetry: _load)
            : _buildForm(),
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  label: 'SIMPAN PENGATURAN',
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    final qrUrl = _setting?.qrUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('QR Pembayaran', style: AppTextStyles.subtitle),
                      const SizedBox(height: 4),
                      Text(
                        'Satu QR dipakai untuk semua event berbayar.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildQrPreview(qrUrl),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: _pickedQr == null
                            ? 'PILIH GAMBAR QR'
                            : 'GANTI GAMBAR QR',
                        icon: Icons.image_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: _pickQr,
                      ),
                      if (_pickedQr != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'QR baru akan dipakai setelah kamu menekan Simpan.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Rekening Tujuan', style: AppTextStyles.subtitle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nama Pemilik',
                        hint: 'Contoh: BEM Polinela',
                        controller: _accountNameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nomor Rekening / Keterangan',
                        hint: 'Contoh: 1234567890 (BNI)',
                        controller: _accountNumberController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Catatan',
                        hint: 'Contoh: Transfer sesuai nominal tiket.',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Kontak Admin', style: AppTextStyles.subtitle),
                      const SizedBox(height: 4),
                      Text(
                        'Nomor ini tampil di halaman login supaya peserta bisa menghubungi admin kalau ada kendala.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Nomor HP / WhatsApp Admin',
                        hint: '0812-3456-7890',
                        controller: _adminPhoneController,
                        keyboardType: TextInputType.phone,
                        validator: Validators.adminPhone,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peserta melihat QR dan nomor rekening ini di halaman pembayaran setiap event berbayar.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrPreview(String? qrUrl) {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.contain);
    }

    if (qrUrl == null || qrUrl.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada QR.\nPilih gambar QR pembayaran.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return Image.network(
      qrUrl,
      headers: ApiConfig.mediaHeaders,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Center(child: Text('QR gagal dimuat.', style: AppTextStyles.caption)),
    );
  }
}
