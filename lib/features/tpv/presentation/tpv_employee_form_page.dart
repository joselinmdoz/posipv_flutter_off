import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_form_widgets.dart';

class TpvEmployeeFormPage extends ConsumerStatefulWidget {
  const TpvEmployeeFormPage({super.key, this.employee});

  final TpvEmployee? employee;

  @override
  ConsumerState<TpvEmployeeFormPage> createState() =>
      _TpvEmployeeFormPageState();
}

class _TpvEmployeeFormPageState extends ConsumerState<TpvEmployeeFormPage> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _identityCtrl;
  late final TextEditingController _addressCtrl;

  List<TpvUserOption> _userOptions = <TpvUserOption>[];
  String? _selectedSex;
  String? _selectedUserId;
  String? _imagePath;

  bool _loadingUsers = true;
  bool _saving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee?.name ?? '');
    _identityCtrl =
        TextEditingController(text: widget.employee?.identityNumber ?? '');
    _addressCtrl = TextEditingController(text: widget.employee?.address ?? '');
    _selectedSex = widget.employee?.sex?.toUpperCase() == 'M' ||
            widget.employee?.sex?.toUpperCase() == 'F' ||
            widget.employee?.sex?.toUpperCase() == 'X'
        ? widget.employee!.sex!.toUpperCase()
        : null;
    _selectedUserId = widget.employee?.associatedUserId;
    _imagePath = widget.employee?.imagePath;

    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final options =
          await ref.read(tpvLocalDataSourceProvider).listActiveUserOptions();
      if (!mounted) return;
      setState(() {
        _userOptions = options;
        if (_selectedUserId != null &&
            options.every((row) => row.id != _selectedUserId)) {
          _selectedUserId = null;
        }
        _loadingUsers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _pickImage() async {
    final action = await showModalBottomSheet<_EmployeeImageAction>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, _EmployeeImageAction.gallery)),
          ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, _EmployeeImageAction.camera)),
          if ((_imagePath ?? '').isNotEmpty)
            ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Quitar'),
                onTap: () => Navigator.pop(ctx, _EmployeeImageAction.remove)),
        ],
      ),
    );

    if (action == null) return;
    if (action == _EmployeeImageAction.remove) {
      setState(() => _imagePath = null);
      return;
    }

    final XFile? file = await _imagePicker.pickImage(
      source: action == _EmployeeImageAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _show('Nombre completo obligatorio');
      return;
    }

    setState(() => _saving = true);
    try {
      final ds = ref.read(tpvLocalDataSourceProvider);
      if (_isEditing) {
        await ds.updateEmployee(
          employeeId: widget.employee!.id,
          name: name,
          code: widget.employee!.code,
          sex: _selectedSex,
          identityNumber: _identityCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          imagePath: _imagePath,
          associatedUserId: _selectedUserId,
          isActive: widget.employee!.isActive,
        );
      } else {
        await ds.createEmployee(
          name: name,
          sex: _selectedSex,
          identityNumber: _identityCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          imagePath: _imagePath,
          associatedUserId: _selectedUserId,
        );
      }
      if (mounted) Navigator.pop(context, 'saved');
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _show('Error: $e');
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1152D4);
    final cardBg = isDark ? const Color(0xFF1A202E) : Colors.white;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101622) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: primaryColor),
        ),
        title: Text(
            _isEditing ? 'Configuración de Empleado' : 'Registro de Empleado',
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header Profile Photo
                TpvEmployeePhotoPicker(
                  imagePath: _imagePath,
                  onPick: _pickImage,
                  isDark: isDark,
                  disabled: _saving,
                ),
                const SizedBox(height: 40),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(title: 'DATOS PERSONALES'),
                      const SizedBox(height: 16),
                      TpvFormTextField(
                          label: 'Nombre Completo',
                          hintText: 'Ej. Juan Pérez',
                          controller: _nameCtrl,
                          icon: Icons.person_outline_rounded,
                          isDark: isDark),
                      const SizedBox(height: 16),
                      TpvFormTextField(
                          label: 'ID / Cédula',
                          hintText: '000-000000-0000X',
                          controller: _identityCtrl,
                          icon: Icons.badge_outlined,
                          isDark: isDark),
                      const SizedBox(height: 16),
                      const _Label(label: 'Género'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChoice('MASCULINO', 'M', isDark),
                          const SizedBox(width: 8),
                          _buildChoice('FEMENINO', 'F', isDark),
                          const SizedBox(width: 8),
                          _buildChoice('OTRO', 'X', isDark),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(title: 'PROCESO & ACCESO'),
                      const SizedBox(height: 16),
                      _buildUserDropdown(isDark),
                      const SizedBox(height: 16),
                      TpvFormTextField(
                          label: 'Dirección',
                          hintText: 'Domicilio o residencia...',
                          controller: _addressCtrl,
                          icon: Icons.map_outlined,
                          minLines: 3,
                          maxLines: 5,
                          isDark: isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF003CA7)]),
                    boxShadow: [
                      BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text('GUARDAR REGISTRO',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoice(String label, String value, bool isDark) {
    final bool isSelected = _selectedSex == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSex = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1152D4)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildUserDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(label: 'Usuario de Sistema (Login)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: _selectedUserId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.lock_person_outlined,
                size: 20, color: Color(0xFF1152D4)),
          ),
          items: [
            const DropdownMenuItem(
                value: null, child: Text('Asignar más tarde (Sin usuario)')),
            ..._userOptions.map((user) =>
                DropdownMenuItem(value: user.id, child: Text(user.username))),
          ],
          onChanged:
              _loadingUsers ? null : (v) => setState(() => _selectedUserId = v),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1152D4),
            letterSpacing: 1.5));
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1));
  }
}

enum _EmployeeImageAction { gallery, camera, remove }
