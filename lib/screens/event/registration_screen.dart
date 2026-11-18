import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import '../../widgets/member_count_field.dart';
import '../../utils/app_events.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../payment/payment_screen.dart';
import '../ticket/ticket_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.event});

  final Event event;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _nimController;
  late final TextEditingController _emailController;

  XFile? _ktm;
  Uint8List? _ktmBytes;
  late final TextEditingController _teamNameController;
  final List<TextEditingController> _memberNameControllers = [];
  final List<TextEditingController> _memberNimControllers = [];
  final List<XFile?> _memberKtms = [];
  int _memberCount = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  Registration? _registration;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nimController = TextEditingController(text: user?.nim ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _teamNameController = TextEditingController();

    if (widget.event.isTeamEvent) {
      _setMemberCount(widget.event.teamMinMembers ?? 2);
    }
  }

  void _setMemberCount(int value) {
    final normalized = value.clamp(
      widget.event.teamMinMembers ?? 2,
      widget.event.teamMaxMembers ?? 30,
    );

    final teammateCount = normalized - 1;

    while (_memberNameControllers.length < teammateCount) {
      _memberNameControllers.add(TextEditingController());
      _memberNimControllers.add(TextEditingController());
      _memberKtms.add(null);
    }

    while (_memberNameControllers.length > teammateCount) {
      _memberNameControllers.removeLast().dispose();
      _memberNimControllers.removeLast().dispose();
      _memberKtms.removeLast();
    }

    _memberCount = normalized;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _teamNameController.dispose();
    for (final controller in _memberNameControllers) {
      controller.dispose();
    }
    for (final controller in _memberNimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickKtm({int? memberIndex}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
        if (memberIndex == null) {
          _ktm = picked;
          _ktmBytes = bytes;
        } else {
          _memberKtms[memberIndex] = picked;
        }
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Gagal memilih foto KTM. Silakan coba lagi.';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (widget.event.requiresKtm &&
        (widget.event.isTeamEvent
            ? _ktm == null || _memberKtms.any((file) => file == null)
            : _ktm == null)) {
      setState(
        () =>
            _errorMessage = 'KTM wajib diunggah untuk semua anggota event ini.',
      );
      return;
    }

    if (widget.event.isTeamEvent &&
        (_memberNameControllers.any(
              (controller) => controller.text.trim().isEmpty,
            ) ||
            _memberNimControllers.any(
              (controller) => controller.text.trim().isEmpty,
            ))) {
      setState(
        () => _errorMessage = 'Nama dan NIM semua anggota tim wajib diisi.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final registration = await RegistrationService.register(
        widget.event.id,
        participantName: _nameController.text,
        participantNim: _nimController.text,
        participantEmail: _emailController.text,
        ktm: widget.event.isTeamEvent ? null : _ktm,
        teamName: widget.event.isTeamEvent ? _teamNameController.text : null,
        teamMembers: widget.event.isTeamEvent
            ? [
                TeamMemberInput(
                  name: _nameController.text,
                  nim: _nimController.text,
                  ktm: widget.event.requiresKtm ? _ktm : null,
                ),
                for (
                  var index = 0;
                  index < _memberNameControllers.length;
                  index++
                )
                  TeamMemberInput(
                    name: _memberNameControllers[index].text,
                    nim: _memberNimControllers[index].text,
                    ktm: widget.event.requiresKtm ? _memberKtms[index] : null,
                  ),
              ]
            : const [],
      );

      AppEvents.notifyDataChanged();

      if (!mounted) {
        return;
      }

      if (!registration.hasTicket) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentScreen(registration: registration),
          ),
        );
        return;
      }

      setState(() {
        _registration = registration;
        _isSubmitting = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = error.firstValidationError ?? error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  void _openTicket() {
    final registration = _registration;

    if (registration == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TicketScreen(registration: registration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _registration != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuccess ? 'Pendaftaran Berhasil' : 'Konfirmasi Pendaftaran',
        ),
        automaticallyImplyLeading: !isSuccess,
      ),
      body: SafeArea(child: isSuccess ? _buildSuccess() : _buildConfirmation()),
      bottomNavigationBar: isSuccess ? null : _buildBottomBar(),
    );
  }

  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Periksa dan lengkapi data peserta sebelum mendaftar.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!widget.event.isTeamEvent) ...[
                  _buildParticipantCard(),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (widget.event.isTeamEvent) ...[
                  _buildTeamCard(),
                  const SizedBox(height: AppSpacing.md),
                ] else if (widget.event.requiresKtm) ...[
                  _KtmPicker(
                    bytes: _ktmBytes,
                    required: true,
                    onTap: _pickKtm,
                    onRemove: _ktm == null
                        ? null
                        : () => setState(() {
                            _ktm = null;
                            _ktmBytes = null;
                          }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _SectionCard(
                  title: 'Detail Event',
                  icon: Icons.event_outlined,
                  children: [
                    _DetailRow(label: 'Event', value: widget.event.title),
                    _DetailRow(
                      label: 'Tanggal',
                      value: Formatters.fullDate(widget.event.date),
                    ),
                    _DetailRow(
                      label: 'Waktu',
                      value: Formatters.timeRange(
                        widget.event.startTime,
                        widget.event.endTime,
                      ),
                    ),
                    _DetailRow(label: 'Lokasi', value: widget.event.location),
                    _DetailRow(
                      label: 'Penyelenggara',
                      value: widget.event.organizer,
                    ),
                    _DetailRow(
                      label: 'Harga Tiket',
                      value: widget.event.priceLabel,
                    ),
                    if (widget.event.registrationDeadlineDate != null &&
                        widget.event.registrationDeadlineTime != null)
                      _DetailRow(
                        label: 'Terakhir Daftar',
                        value:
                            '${Formatters.fullDate(widget.event.registrationDeadlineDate)} • ${Formatters.time(widget.event.registrationDeadlineTime)} WIB',
                      ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorMessage(message: _errorMessage!),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.event.isPaidEvent
                            ? 'Setelah konfirmasi, kamu akan diarahkan ke QR pembayaran. Tiket terbit setelah admin memverifikasi bukti bayar.'
                            : 'Dengan menekan tombol di bawah, kamu setuju mengikuti event ini dan tiket digital akan dibuat otomatis.',
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

  Widget _buildParticipantCard() {
    return _SectionCard(
      title: 'Data Peserta',
      icon: Icons.person_outline_rounded,
      children: [
        AppTextField(
          label: 'Nama Lengkap',
          hint: 'Nama sesuai KTM',
          controller: _nameController,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: Validators.name,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'NIM',
          hint: 'NIM sesuai KTM',
          controller: _nimController,
          prefixIcon: Icons.badge_outlined,
          textInputAction: TextInputAction.next,
          validator: Validators.nim,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email',
          hint: 'Email peserta',
          controller: _emailController,
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
      ],
    );
  }

  Widget _buildTeamCard() {
    final minMembers = widget.event.teamMinMembers ?? 2;
    final maxMembers = widget.event.teamMaxMembers ?? 30;

    return _SectionCard(
      title: 'Data Tim',
      icon: Icons.groups_outlined,
      children: [
        AppTextField(
          label: 'Nama Tim',
          hint: 'Contoh: PoliVent Esports',
          controller: _teamNameController,
          prefixIcon: Icons.groups_outlined,
          validator: (value) => Validators.required(value, label: 'Nama tim'),
        ),
        const SizedBox(height: AppSpacing.md),
        MemberCountField(
          label: 'Jumlah Anggota (termasuk ketua)',
          value: _memberCount,
          onChanged: (value) => setState(() => _setMemberCount(value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Admin menetapkan $minMembers sampai $maxMembers anggota, termasuk ketua tim.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Ketua Tim', style: AppTextStyles.bodyStrong),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Nama Ketua',
          hint: 'Nama sesuai KTM',
          controller: _nameController,
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: Validators.name,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'NIM Ketua',
          hint: 'NIM sesuai KTM',
          controller: _nimController,
          prefixIcon: Icons.badge_outlined,
          textInputAction: TextInputAction.next,
          validator: Validators.nim,
        ),
        if (widget.event.requiresKtm) ...[
          const SizedBox(height: AppSpacing.sm),
          _KtmPicker(
            bytes: _ktmBytes,
            required: true,
            compact: true,
            onTap: _pickKtm,
            onRemove: _ktm == null
                ? null
                : () => setState(() {
                    _ktm = null;
                    _ktmBytes = null;
                  }),
          ),
        ],
        for (var index = 0; index < _memberNameControllers.length; index++) ...[
          const Divider(height: 28),
          Text('Anggota ${index + 2}', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Nama Anggota ${index + 2}',
            hint: 'Nama lengkap anggota',
            controller: _memberNameControllers[index],
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) => Validators.name(value),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'NIM Anggota ${index + 2}',
            hint: 'NIM sesuai KTM',
            controller: _memberNimControllers[index],
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.text,
            validator: Validators.nim,
          ),
          if (widget.event.requiresKtm) ...[
            const SizedBox(height: AppSpacing.sm),
            _KtmPicker(
              bytes: null,
              fileName: _memberKtms[index]?.name,
              required: true,
              compact: true,
              onTap: () => _pickKtm(memberIndex: index),
              onRemove: _memberKtms[index] == null
                  ? null
                  : () => setState(() => _memberKtms[index] = null),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 52,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Pendaftaran Berhasil!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tiket kamu sudah tersedia. Tunjukkan QR Code pada tiket saat menghadiri event.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _registration!.event?.title ?? widget.event.title,
                            style: AppTextStyles.subtitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: _registration!.statusLabel,
                          color: _registration!.isAttended
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _registration!.ticketCode ?? '-',
                          style: AppTextStyles.bodyStrong.copyWith(
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'LIHAT TIKET',
                icon: Icons.qr_code_2_rounded,
                onPressed: _openTicket,
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Kembali ke Beranda',
                variant: AppButtonVariant.outlined,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: widget.event.isPaidEvent
              ? 'LANJUT KE PEMBAYARAN'
              : 'KONFIRMASI PENDAFTARAN',
          icon: widget.event.isPaidEvent
              ? Icons.payments_outlined
              : Icons.check_circle_outline_rounded,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ),
    );
  }
}

class _KtmPicker extends StatelessWidget {
  const _KtmPicker({
    required this.bytes,
    required this.required,
    required this.onTap,
    this.onRemove,
    this.fileName,
    this.compact = false,
  });

  final Uint8List? bytes;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String? fileName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: required
          ? 'Kartu Tanda Mahasiswa (KTM) *'
          : 'Kartu Tanda Mahasiswa (KTM)',
      icon: Icons.badge_outlined,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: compact ? 96 : 168,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
              image: bytes == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.contain,
                    ),
            ),
            child: bytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        fileName == null
                            ? Icons.upload_file_rounded
                            : Icons.check_circle_rounded,
                        size: compact ? 26 : 34,
                        color: fileName == null
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      SizedBox(height: compact ? 4 : 8),
                      Text(
                        fileName ?? 'Pilih foto KTM',
                        style: AppTextStyles.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          'JPG, PNG, atau WEBP • maks 4 MB',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.error,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      tooltip: 'Hapus KTM',
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          required
              ? 'KTM wajib diunggah untuk event ini.'
              : 'KTM hanya diminta jika diwajibkan admin event.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyStrong)),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
