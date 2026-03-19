import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';

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
      final List<TpvUserOption> options =
          await ref.read(tpvLocalDataSourceProvider).listActiveUserOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _userOptions = options;
        if (_selectedUserId != null &&
            options.every((TpvUserOption row) => row.id != _selectedUserId)) {
          _selectedUserId = null;
        }
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _userOptions = <TpvUserOption>[];
        _selectedUserId = null;
        _loadingUsers = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final _EmployeeImageAction? action =
        await showModalBottomSheet<_EmployeeImageAction>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería'),
                onTap: () => Navigator.of(context)
                    .pop(_EmployeeImageAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cámara'),
                onTap: () => Navigator.of(context)
                    .pop(_EmployeeImageAction.camera),
              ),
              if ((_imagePath ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Quitar imagen'),
                  onTap: () => Navigator.of(context)
                      .pop(_EmployeeImageAction.remove),
                ),
            ],
          ),
        );
      },
    );

    if (action == null) {
      return;
    }

    if (action == _EmployeeImageAction.remove) {
      setState(() => _imagePath = null);
      return;
    }

    final XFile? file = await _imagePicker.pickImage(
      source: action == _EmployeeImageAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );

    if (file == null || !mounted) {
      return;
    }

    setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _show('El nombre completo es obligatorio.');
      return;
    }

    setState(() => _saving = true);

    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
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

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('saved');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
      _show('No se pudo guardar registro: $e');
    }
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155), // slate-300 : text-slate-700
            ),
          ),
        ),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
          style: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), // slate-500 : slate-400
              fontSize: 15,
            ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1152D4),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSexOption(String label, String value) {
    final bool selected = _selectedSex == value;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: _saving ? null : () => setState(() => _selectedSex = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1152D4)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1152D4)
                  : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF1152D4).withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // slate-900 : slate-50
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          _isEditing ? 'Editar Empleado' : 'Registro de Empleado',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF1152D4),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // slate-800 : slate-100
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
            child: SizedBox(
               width: double.infinity,
               child: _buildForm(theme, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Si la pantalla es lo suficientemente amplia, se divide en 2 columnas,
        // parecido al grid-cols-1 md:grid-cols-12 del HTML.
        if (width >= 768) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Sidebar (md:col-span-4)
              Expanded(
                flex: 4,
                child: _buildPhotoSidebar(theme, isDark),
              ),
              const SizedBox(width: 40),
              // Fields Container (md:col-span-8)
              Expanded(
                flex: 8,
                child: _buildFieldsContainer(theme, isDark),
              ),
            ],
          );
        } else {
          // Mobile view
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPhotoSidebar(theme, isDark),
              const SizedBox(height: 32),
              _buildFieldsContainer(theme, isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildPhotoSidebar(ThemeData theme, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _saving ? null : _pickImage,
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC), // slate-800 : slate-50
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), // slate-700 : slate-200
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A000000), // shadow-sm
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: _imagePath != null && _imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(_imagePath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 64,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), // slate-600 : slate-300
                        ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1152D4),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF1152D4).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4), // shadow-lg
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FORMATO JPG O PNG',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), // slate-500
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldsContainer(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Nombre Completo',
          hintText: 'Ej. Alejandro Valenzuela',
          controller: _nameCtrl,
        ),
        const SizedBox(height: 24),
        // Grid 2 columns for ID and Phone equivalent
        LayoutBuilder(
          builder: (context, constraints) {
            // Using MediaQuery or just the constraints to break into row
            if (constraints.maxWidth >= 400) {
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Número de Identidad',
                      hintText: '000-000000-0000X',
                      controller: _identityCtrl,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Using "Usuario asociado" instead of Phone to keep functionality
                  Expanded(
                    child: _buildUserDropdown(theme, isDark),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildTextField(
                    label: 'Número de Identidad',
                    hintText: '000-000000-0000X',
                    controller: _identityCtrl,
                  ),
                  const SizedBox(height: 24),
                  _buildUserDropdown(theme, isDark),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Sexo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSexOption('Masculino', 'M'),
            const SizedBox(width: 12),
            _buildSexOption('Femenino', 'F'),
            const SizedBox(width: 12),
            _buildSexOption('Otro', 'X'),
          ],
        ),
        const SizedBox(height: 28),
        _buildTextField(
          label: 'Dirección Domiciliaria',
          hintText: 'Calle, Número, Ciudad...',
          controller: _addressCtrl,
          minLines: 3,
          maxLines: 4,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1152D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF1152D4).withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.save_rounded),
            label: Text(
              _saving ? 'Guardando...' : 'Guardar Registro',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDropdown(ThemeData theme, bool isDark) {
    if (_loadingUsers) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Usuario Asociado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Usuario Asociado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
        DropdownButtonFormField<String?>(
          value: _selectedUserId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1152D4),
                width: 2,
              ),
            ),
          ),
          items: [
            const DropdownMenuItem(
                value: null, child: Text('Sin usuario (vacio)')),
            ..._userOptions.map(
              (TpvUserOption user) => DropdownMenuItem(
                value: user.id,
                child: Text(user.username),
              ),
            )
          ],
          onChanged: _saving
              ? null
              : (String? v) => setState(() => _selectedUserId = v),
        ),
      ],
    );
  }
}
enum _EmployeeImageAction { gallery, camera, remove }
