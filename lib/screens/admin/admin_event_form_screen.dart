import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/event_service.dart';
import '../../utils/app_events.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/member_count_field.dart';

class AdminEventFormScreen extends StatefulWidget {
  const AdminEventFormScreen({super.key, this.event});

  final Event? event;

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _organizerController;
  late final TextEditingController _quotaController;
  late final TextEditingController _priceController;

  List<Category> _categories = const [];
  int? _categoryId;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  XFile? _banner;
  Uint8List? _bannerBytes;
  XFile? _qr;
  Uint8List? _qrBytes;

  bool _requiresKtm = false;
  String _registrationType = 'individual';
  int _teamMinMembers = 2;
  int _teamMaxMembers = 5;
  DateTime? _registrationDeadlineDate;
  TimeOfDay? _registrationDeadlineTime;
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _organizerController = TextEditingController(text: event?.organizer ?? '');
    _quotaController = TextEditingController(
      text: event == null ? '' : '${event.quota}',
    );
    _priceController = TextEditingController(text: '${event?.price ?? 0}');

    _categoryId = event?.categoryId;
    _requiresKtm = event?.requiresKtm ?? false;
    _registrationType = event?.registrationType ?? 'individual';
    _teamMinMembers = event?.teamMinMembers ?? 2;
    _teamMaxMembers = event?.teamMaxMembers ?? 5;
    _registrationDeadlineDate = event?.registrationDeadlineDate;
    _registrationDeadlineTime = event?.registrationDeadlineTime == null
        ? null
        : _parseTime(
            event!.registrationDeadlineTime,
            const TimeOfDay(hour: 23, minute: 59),
          );
    _date = event?.date ?? DateTime.now().add(const Duration(days: 7));
    _startTime = _parseTime(
      event?.startTime,
      const TimeOfDay(hour: 8, minute: 0),
    );
    _endTime = _parseTime(event?.endTime, const TimeOfDay(hour: 12, minute: 0));

    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _quotaController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    if (value == null || value.isEmpty) {
      return fallback;
    }

    final parts = value.split(':');

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await EventService.getCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCategories = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCategories = false;
        _errorMessage = 'Gagal memuat kategori. Silakan coba lagi.';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickRegistrationDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadlineDate ?? _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null && mounted) {
      setState(() => _registrationDeadlineDate = picked);
    }
  }

  Future<void> _pickRegistrationDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _registrationDeadlineTime ?? const TimeOfDay(hour: 23, minute: 59),
    );

    if (picked != null && mounted) {
      setState(() => _registrationDeadlineTime = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _showBannerSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _banner = picked;
        _bannerBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'Gagal memilih gambar. Coba lagi.',
        isError: true,
      );
    }
  }

  Future<void> _pickQr() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _qr = picked;
        _qrBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'Gagal memilih gambar QRIS. Coba lagi.',
        isError: true,
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_categoryId == null) {
      setState(() => _errorMessage = 'Kategori wajib dipilih.');
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() => _errorMessage = 'Jam selesai harus setelah jam mulai.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final quota = int.parse(_quotaController.text.trim());
      final price =
          int.tryParse(_priceController.text.replaceAll('.', '').trim()) ?? 0;
      final startTime = Formatters.apiTime(_startTime.hour, _startTime.minute);
      final endTime = Formatters.apiTime(_endTime.hour, _endTime.minute);

      if (_isEditing) {
        await EventService.updateEvent(
          id: widget.event!.id,
          categoryId: _categoryId!,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _date,
          startTime: startTime,
          endTime: endTime,
          location: _locationController.text,
          organizer: _organizerController.text,
          quota: quota,
          price: price,
          requiresKtm: _requiresKtm,
          registrationType: _registrationType,
          teamMinMembers: _registrationType == 'team' ? _teamMinMembers : null,
          teamMaxMembers: _registrationType == 'team' ? _teamMaxMembers : null,
          registrationDeadlineDate: _registrationDeadlineDate,
          registrationDeadlineTime:
              _registrationDeadlineDate == null ||
                  _registrationDeadlineTime == null
              ? null
              : Formatters.apiTime(
                  _registrationDeadlineTime!.hour,
                  _registrationDeadlineTime!.minute,
                ),
          banner: _banner,
          qr: _qr,
        );
      } else {
        await EventService.createEvent(
          categoryId: _categoryId!,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _date,
          startTime: startTime,
          endTime: endTime,
          location: _locationController.text,
          organizer: _organizerController.text,
          quota: quota,
          price: price,
          requiresKtm: _requiresKtm,
          registrationType: _registrationType,
          teamMinMembers: _registrationType == 'team' ? _teamMinMembers : null,
          teamMaxMembers: _registrationType == 'team' ? _teamMaxMembers : null,
          registrationDeadlineDate: _registrationDeadlineDate,
          registrationDeadlineTime:
              _registrationDeadlineDate == null ||
                  _registrationDeadlineTime == null
              ? null
              : Formatters.apiTime(
                  _registrationDeadlineTime!.hour,
                  _registrationDeadlineTime!.minute,
                ),
          banner: _banner,
          qr: _qr,
        );
      }

      AppEvents.notifyDataChanged();

      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        _isEditing ? 'Event berhasil diperbarui.' : 'Event berhasil dibuat.',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = error.firstValidationError ?? error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Tambah Event')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BannerPicker(
                      bytes: _bannerBytes,
                      onTap: _showBannerSource,
                      onRemove: _bannerBytes == null
                          ? null
                          : () => setState(() {
                              _banner = null;
                              _bannerBytes = null;
                            }),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Judul Event',
                      hint: 'Contoh: Seminar Nasional Teknologi',
                      controller: _titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (value) =>
                          Validators.required(value, label: 'Judul event'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<int>(
                          initialValue: _categoryId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: _isLoadingCategories
                                ? 'Memuat kategori...'
                                : 'Pilih kategori',
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoadingCategories
                              ? null
                              : (value) => setState(() => _categoryId = value),
                          validator: (value) =>
                              value == null ? 'Kategori wajib dipilih.' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Deskripsi',
                      hint: 'Jelaskan detail event...',
                      controller: _descriptionController,
                      maxLines: 5,
                      validator: (value) =>
                          Validators.required(value, label: 'Deskripsi'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PickerField(
                      label: 'Tanggal',
                      value: Formatters.fullDate(_date),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerField(
                            label: 'Jam Mulai',
                            value: Formatters.time(
                              Formatters.apiTime(
                                _startTime.hour,
                                _startTime.minute,
                              ),
                            ),
                            icon: Icons.schedule_rounded,
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _PickerField(
                            label: 'Jam Selesai',
                            value: Formatters.time(
                              Formatters.apiTime(
                                _endTime.hour,
                                _endTime.minute,
                              ),
                            ),
                            icon: Icons.schedule_rounded,
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Lokasi',
                      hint: 'Contoh: Aula Polinela',
                      controller: _locationController,
                      prefixIcon: Icons.place_outlined,
                      validator: (value) =>
                          Validators.required(value, label: 'Lokasi'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Penyelenggara',
                      hint: 'Contoh: BEM Polinela',
                      controller: _organizerController,
                      prefixIcon: Icons.account_balance_outlined,
                      validator: (value) =>
                          Validators.required(value, label: 'Penyelenggara'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Kuota',
                      hint: 'Contoh: 100',
                      controller: _quotaController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.groups_outlined,
                      validator: Validators.quota,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Harga Tiket (Rp)',
                      hint: 'Isi 0 untuk event gratis',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.payments_outlined,
                      validator: Validators.price,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QrPicker(
                      bytes: _qrBytes,
                      qrUrl: widget.event?.qrUrl,
                      onTap: _pickQr,
                      onRemove: _qrBytes == null
                          ? null
                          : () => setState(() {
                              _qr = null;
                              _qrBytes = null;
                            }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Jenis Pendaftaran', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'individual',
                          icon: Icon(Icons.person_outline_rounded),
                          label: Text('Individu'),
                        ),
                        ButtonSegment(
                          value: 'team',
                          icon: Icon(Icons.groups_outlined),
                          label: Text('Tim'),
                        ),
                      ],
                      selected: {_registrationType},
                      onSelectionChanged: (value) =>
                          setState(() => _registrationType = value.first),
                    ),
                    if (_registrationType == 'team') ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: MemberCountField(
                              label: 'Minimal Anggota',
                              value: _teamMinMembers,
                              onChanged: (value) =>
                                  setState(() => _teamMinMembers = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: MemberCountField(
                              label: 'Maksimal Anggota',
                              value: _teamMaxMembers,
                              onChanged: (value) =>
                                  setState(() => _teamMaxMembers = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Kuota dan harga tiket dihitung per tim. Jumlah anggota termasuk ketua.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Tanggal & Jam Terakhir Mendaftar Event',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerField(
                            label: 'Tanggal',
                            value: _registrationDeadlineDate == null
                                ? 'Pilih tanggal terakhir mendaftar'
                                : Formatters.fullDate(
                                    _registrationDeadlineDate,
                                  ),
                            icon: Icons.event_available_outlined,
                            onTap: _pickRegistrationDeadlineDate,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _PickerField(
                            label: 'Jam',
                            value: _registrationDeadlineTime == null
                                ? 'Pilih jam'
                                : Formatters.time(
                                    Formatters.apiTime(
                                      _registrationDeadlineTime!.hour,
                                      _registrationDeadlineTime!.minute,
                                    ),
                                  ),
                            icon: Icons.schedule_rounded,
                            onTap: _pickRegistrationDeadlineTime,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Setelah waktu ini lewat, event tidak lagi tampil untuk peserta. Event tetap tersimpan di riwayat admin.',
                      style: AppTextStyles.caption,
                    ),
                    if (_registrationDeadlineDate != null ||
                        _registrationDeadlineTime != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _registrationDeadlineDate = null;
                            _registrationDeadlineTime = null;
                          }),
                          child: const Text('Hapus batas pendaftaran'),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _requiresKtm,
                      onChanged: (value) =>
                          setState(() => _requiresKtm = value),
                      title: Text(
                        'Wajib unggah KTM',
                        style: AppTextStyles.bodyStrong,
                      ),
                      subtitle: Text(
                        'Peserta harus unggah foto KTM sebelum mendaftar.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'QRIS di atas opsional. Jika tidak diunggah, event berbayar '
                      'akan memakai QR pembayaran global. Tiket peserta baru '
                      'terbit setelah admin memverifikasi bukti bayar.',
                      style: AppTextStyles.caption,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: _isEditing ? 'SIMPAN PERUBAHAN' : 'SIMPAN EVENT',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(value, style: AppTextStyles.bodyStrong)),
                  Icon(icon, size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerPicker extends StatelessWidget {
  const _BannerPicker({
    required this.bytes,
    required this.onTap,
    this.onRemove,
  });

  final Uint8List? bytes;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Banner Event', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 168,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              image: bytes == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: bytes == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 34,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih banner event',
                          style: AppTextStyles.bodyStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'JPG, PNG, atau WEBP • maks 2 MB',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BannerAction(
                            icon: Icons.edit_outlined,
                            onTap: onTap,
                          ),
                          if (onRemove != null) ...[
                            const SizedBox(width: 8),
                            _BannerAction(
                              icon: Icons.close_rounded,
                              onTap: onRemove!,
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _QrPicker extends StatelessWidget {
  const _QrPicker({
    required this.bytes,
    required this.qrUrl,
    required this.onTap,
    this.onRemove,
  });

  final Uint8List? bytes;
  final String? qrUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasExistingQr = qrUrl != null && qrUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QRIS Event (Opsional)', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(bytes!, fit: BoxFit.contain),
                  )
                else if (hasExistingQr)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.network(
                      qrUrl!,
                      headers: ApiConfig.mediaHeaders,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text(
                              'QRIS gagal dimuat. Ketuk untuk mengganti.',
                            ),
                          ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih gambar QRIS',
                          style: AppTextStyles.bodyStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Peserta akan melihat QR ini saat membayar',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BannerAction(icon: Icons.edit_outlined, onTap: onTap),
                        if (onRemove != null) ...[
                          const SizedBox(width: 8),
                          _BannerAction(
                            icon: Icons.close_rounded,
                            onTap: onRemove!,
                            color: AppColors.error,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerAction extends StatelessWidget {
  const _BannerAction({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
