import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../configuracion/presentation/work_order_task_types_settings_page.dart';
import '../../configuracion/presentation/work_order_task_worker_roles_settings_page.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_searchable_select_field.dart';
import '../data/pedidos_local_datasource.dart';
import 'pedidos_providers.dart';
import 'widgets/work_order_task_material_dialog.dart';
import 'widgets/work_order_task_worker_dialog.dart';

class PedidoTaskFormPage extends ConsumerStatefulWidget {
  const PedidoTaskFormPage({
    super.key,
    required this.productOptions,
    required this.employeeOptions,
    required this.taskTypeOptions,
    required this.taskWorkerRoleOptions,
    this.initialTask,
  });

  final List<WorkOrderProductOption> productOptions;
  final List<WorkOrderEmployeeOption> employeeOptions;
  final List<String> taskTypeOptions;
  final List<String> taskWorkerRoleOptions;
  final WorkOrderTaskItem? initialTask;

  @override
  ConsumerState<PedidoTaskFormPage> createState() => _PedidoTaskFormPageState();
}

class _PedidoTaskFormPageState extends ConsumerState<PedidoTaskFormPage> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _descriptionCtrl;

  List<String> _taskTypeOptions = <String>[];
  List<WorkOrderTaskMaterialItem> _materials = <WorkOrderTaskMaterialItem>[];
  List<WorkOrderTaskMaterialItem> _wasteMaterials =
      <WorkOrderTaskMaterialItem>[];
  List<WorkOrderTaskWorkerItem> _workers = <WorkOrderTaskWorkerItem>[];
  List<String> _imagePaths = <String>[];
  List<String> _taskWorkerRoleOptions = <String>[];
  bool _saving = false;
  String? _selectedTaskType;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl = TextEditingController();
    _taskTypeOptions = List<String>.of(widget.taskTypeOptions);
    _taskWorkerRoleOptions = List<String>.of(widget.taskWorkerRoleOptions);
    final WorkOrderTaskItem? initialTask = widget.initialTask;
    if (initialTask != null) {
      _descriptionCtrl.text = initialTask.description ?? '';
      _materials = List<WorkOrderTaskMaterialItem>.of(initialTask.materials);
      _wasteMaterials =
          List<WorkOrderTaskMaterialItem>.of(initialTask.wasteMaterials);
      _workers = List<WorkOrderTaskWorkerItem>.of(initialTask.workers);
      _imagePaths = List<String>.of(initialTask.imagePaths);
      _selectedTaskType = initialTask.title;
      if (_selectedTaskType != null &&
          _selectedTaskType!.trim().isNotEmpty &&
          !_taskTypeOptions.contains(_selectedTaskType)) {
        _taskTypeOptions = <String>[_selectedTaskType!, ..._taskTypeOptions];
      }
    } else if (_taskTypeOptions.isNotEmpty) {
      _selectedTaskType = _taskTypeOptions.first;
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMaterial([int? index]) async {
    final WorkOrderTaskMaterialItem? current =
        index == null ? null : _materials[index];
    final WorkOrderTaskMaterialItem? created =
        await showDialog<WorkOrderTaskMaterialItem>(
      context: context,
      builder: (_) => WorkOrderTaskMaterialDialog(
        options: widget.productOptions,
        initialItem: current,
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _materials = <WorkOrderTaskMaterialItem>[..._materials, created];
      } else {
        final List<WorkOrderTaskMaterialItem> next =
            List<WorkOrderTaskMaterialItem>.of(_materials);
        next[index] = created;
        _materials = next;
      }
    });
  }

  Future<void> _addWorker([int? index]) async {
    final WorkOrderTaskWorkerItem? current =
        index == null ? null : _workers[index];
    final WorkOrderTaskWorkerItem? created =
        await showDialog<WorkOrderTaskWorkerItem>(
      context: context,
      builder: (_) => WorkOrderTaskWorkerDialog(
        options: widget.employeeOptions,
        roleOptions: _taskWorkerRoleOptions,
        initialItem: current,
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _workers = <WorkOrderTaskWorkerItem>[..._workers, created];
      } else {
        final List<WorkOrderTaskWorkerItem> next =
            List<WorkOrderTaskWorkerItem>.of(_workers);
        next[index] = created;
        _workers = next;
      }
    });
  }

  Future<void> _addWasteMaterial([int? index]) async {
    final WorkOrderTaskMaterialItem? current =
        index == null ? null : _wasteMaterials[index];
    final WorkOrderTaskMaterialItem? created =
        await showDialog<WorkOrderTaskMaterialItem>(
      context: context,
      builder: (_) => WorkOrderTaskMaterialDialog(
        options: widget.productOptions,
        initialItem: current,
        titleOverride:
            index == null ? 'Agregar producto de merma' : 'Editar merma',
        quantityLabel: 'Cantidad de merma',
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _wasteMaterials = <WorkOrderTaskMaterialItem>[
          ..._wasteMaterials,
          created,
        ];
      } else {
        final List<WorkOrderTaskMaterialItem> next =
            List<WorkOrderTaskMaterialItem>.of(_wasteMaterials);
        next[index] = created;
        _wasteMaterials = next;
      }
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      final List<WorkOrderTaskMaterialItem> next =
          List<WorkOrderTaskMaterialItem>.of(_materials);
      next.removeAt(index);
      _materials = next;
    });
  }

  void _removeWorker(int index) {
    setState(() {
      final List<WorkOrderTaskWorkerItem> next =
          List<WorkOrderTaskWorkerItem>.of(_workers);
      next.removeAt(index);
      _workers = next;
    });
  }

  void _removeWasteMaterial(int index) {
    setState(() {
      final List<WorkOrderTaskMaterialItem> next =
          List<WorkOrderTaskMaterialItem>.of(_wasteMaterials);
      next.removeAt(index);
      _wasteMaterials = next;
    });
  }

  Future<void> _pickImages() async {
    if (_saving) {
      return;
    }
    final _TaskImageAction? action =
        await showModalBottomSheet<_TaskImageAction>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Agregar desde galería'),
              onTap: () => Navigator.of(ctx).pop(_TaskImageAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(_TaskImageAction.camera),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) {
      return;
    }
    try {
      if (action == _TaskImageAction.gallery) {
        final List<XFile> files = await _imagePicker.pickMultiImage(
          imageQuality: 85,
        );
        if (!mounted || files.isEmpty) {
          return;
        }
        setState(() {
          _imagePaths = <String>{
            ..._imagePaths,
            ...files.map((XFile file) => file.path),
          }.toList(growable: false);
        });
        return;
      }
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (!mounted || file == null) {
        return;
      }
      setState(() {
        _imagePaths = <String>{..._imagePaths, file.path}.toList(
          growable: false,
        );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudieron cargar las imágenes: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      final List<String> next = List<String>.of(_imagePaths);
      next.removeAt(index);
      _imagePaths = next;
    });
  }

  void _save() {
    final String taskType = (_selectedTaskType ?? '').trim();
    if (taskType.isEmpty) {
      _show('Selecciona el tipo de trabajo realizado.');
      return;
    }
    if (_workers.isEmpty) {
      _show('Agrega al menos un trabajador que participo.');
      return;
    }
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    Navigator.of(context).pop(
      WorkOrderTaskCreateInput(
        title: taskType,
        description: _descriptionCtrl.text.trim(),
        materials: _materials,
        wasteMaterials: _wasteMaterials,
        workers: _workers,
        imagePaths: _imagePaths,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar trabajo realizado' : 'Trabajo realizado',
      currentRoute: '/pedidos',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: <Widget>[
          if (_saving) const LinearProgressIndicator(minHeight: 3),
          _SectionCard(
            title: 'Datos del trabajo',
            children: <Widget>[
              AppSearchableSelectField<String>(
                label: 'Tipo de trabajo',
                value: _selectedTaskType,
                hintText: 'Selecciona el tipo de trabajo',
                options: _taskTypeOptions
                    .map(
                      (String type) => AppSearchableSelectOption<String>(
                        value: type,
                        label: type,
                        searchText: type,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (String value) {
                  setState(() => _selectedTaskType = value);
                },
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkOrderTaskTypesSettingsPage(),
                      ),
                    );
                    if (!mounted) {
                      return;
                    }
                    final List<String> refreshed = await ref
                        .read(pedidosLocalDataSourceProvider)
                        .listActiveTaskTypeOptions();
                    if (!mounted || refreshed.isEmpty) {
                      return;
                    }
                    setState(() {
                      _taskTypeOptions = List<String>.of(refreshed);
                      if (!refreshed.contains(_selectedTaskType)) {
                        _selectedTaskType = refreshed.first;
                      }
                    });
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Gestionar tipos de trabajo'),
                ),
              ),
              const SizedBox(height: 8),
              const _FieldLabel('Descripcion'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: _inputDecoration(
                  'Describe lo que se hizo en esta etapa...',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: _FieldLabel('Evidencias del trabajo'),
                  ),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _imagePaths.isEmpty ? 'Agregar' : 'Agregar más',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_imagePaths.isEmpty)
                const _EmptyHint(
                  'Aun no has agregado imágenes del trabajo terminado.',
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _imagePaths.asMap().entries.map(
                    (MapEntry<int, String> entry) {
                      final File file = File(entry.value);
                      return Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 94,
                              height: 94,
                              color: const Color(0xFFE2E8F0),
                              child: file.existsSync()
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.broken_image_outlined,
                                      color: Color(0xFF64748B),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xCC0F172A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ).toList(growable: false),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Materiales usados',
            actionLabel: 'Agregar',
            onAction: _addMaterial,
            children: <Widget>[
              if (_materials.isEmpty)
                const _EmptyHint('Aun no has agregado materiales.')
              else
                ..._materials.asMap().entries.map(
                      (MapEntry<int, WorkOrderTaskMaterialItem> entry) =>
                          Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EditableItemCard(
                          title: entry.value.productName,
                          subtitle: entry.value.areaSqm != null &&
                                  entry.value.widthMeters != null &&
                                  entry.value.heightMeters != null
                              ? '${_qty(entry.value.qty)} ${entry.value.unitLabel} · ${_qty(entry.value.widthMeters!)} m x ${_qty(entry.value.heightMeters!)} m'
                              : '${_qty(entry.value.qty)} ${entry.value.unitLabel} · ${entry.value.productSku}',
                          onEdit: () => _addMaterial(entry.key),
                          onDelete: () => _removeMaterial(entry.key),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          const _InfoCallout(
            message:
                'Puedes guardar trabajos sin materiales ni merma cuando la etapa no consume insumos, por ejemplo diseno o corte.',
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Productos de merma',
            actionLabel: 'Agregar',
            onAction: _addWasteMaterial,
            children: <Widget>[
              if (_wasteMaterials.isEmpty)
                const _EmptyHint(
                  'Aun no has registrado productos de merma.',
                )
              else
                ..._wasteMaterials.asMap().entries.map(
                      (MapEntry<int, WorkOrderTaskMaterialItem> entry) =>
                          Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EditableItemCard(
                          title: entry.value.productName,
                          subtitle: entry.value.areaSqm != null &&
                                  entry.value.widthMeters != null &&
                                  entry.value.heightMeters != null
                              ? '${_qty(entry.value.qty)} ${entry.value.unitLabel} · ${_qty(entry.value.widthMeters!)} m x ${_qty(entry.value.heightMeters!)} m'
                              : '${_qty(entry.value.qty)} ${entry.value.unitLabel} · ${entry.value.productSku}',
                          onEdit: () => _addWasteMaterial(entry.key),
                          onDelete: () => _removeWasteMaterial(entry.key),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Trabajadores que participaron',
            actionLabel: 'Agregar',
            onAction: _addWorker,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const WorkOrderTaskWorkerRolesSettingsPage(),
                      ),
                    );
                    if (!mounted) {
                      return;
                    }
                    final List<String> refreshed = await ref
                        .read(pedidosLocalDataSourceProvider)
                        .listActiveTaskWorkerRoleOptions();
                    if (!mounted || refreshed.isEmpty) {
                      return;
                    }
                    setState(() {
                      _taskWorkerRoleOptions = List<String>.of(refreshed);
                    });
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Gestionar roles de trabajo'),
                ),
              ),
              const SizedBox(height: 8),
              if (_workers.isEmpty)
                const _EmptyHint('Aun no has agregado trabajadores.')
              else
                ..._workers.asMap().entries.map(
                      (MapEntry<int, WorkOrderTaskWorkerItem> entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EditableItemCard(
                          title: entry.value.employeeName,
                          subtitle:
                              '${entry.value.roleName} · ${entry.value.employeeCode}',
                          onEdit: () => _addWorker(entry.key),
                          onDelete: () => _removeWorker(entry.key),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1152D4),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isEditing
                  ? 'Actualizar trabajo realizado'
                  : 'Guardar trabajo realizado',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1152D4)),
      ),
    );
  }
}

enum _TaskImageAction {
  gallery,
  camera,
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if ((actionLabel ?? '').trim().isNotEmpty)
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoCallout extends StatelessWidget {
  const _InfoCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF1152D4),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EditableItemCard extends StatelessWidget {
  const _EditableItemCard({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
