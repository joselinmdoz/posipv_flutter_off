import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/pedidos_local_datasource.dart';
import 'work_order_task_image_viewer_page.dart';
import 'work_order_task_images_reorder_sheet.dart';

class WorkOrderTaskCard extends StatelessWidget {
  const WorkOrderTaskCard({
    super.key,
    required this.task,
    this.canManageImages = false,
    this.onDeleteImage,
    this.onReorderImages,
    this.onEdit,
    this.onDelete,
  });

  final WorkOrderTaskItem task;
  final bool canManageImages;
  final Future<bool> Function(List<String> imagePaths)? onDeleteImage;
  final Future<bool> Function(List<String> imagePaths)? onReorderImages;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateTime(task.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${task.materials.length} materiales',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null) ...<Widget>[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onSelected: (String value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    if (onEdit != null)
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar trabajo'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Eliminar trabajo'),
                      ),
                  ],
                ),
              ],
            ],
          ),
          if ((task.description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              task.description!.trim(),
              style: const TextStyle(
                color: Color(0xFF334155),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (task.materials.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const _MiniTitle('Materiales utilizados'),
            const SizedBox(height: 8),
            ...task.materials.map(
              (WorkOrderTaskMaterialItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RowTile(
                  title: item.productName,
                  subtitle: item.areaSqm != null &&
                          item.widthMeters != null &&
                          item.heightMeters != null
                      ? '${_qty(item.qty)} ${item.unitLabel} · ${_qty(item.widthMeters!)} m x ${_qty(item.heightMeters!)} m'
                      : '${_qty(item.qty)} ${item.unitLabel} · ${item.productSku}',
                ),
              ),
            ),
          ],
          if (task.workers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const _MiniTitle('Trabajadores'),
            const SizedBox(height: 8),
            ...task.workers.map(
              (WorkOrderTaskWorkerItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RowTile(
                  title: item.employeeName,
                  subtitle: '${item.roleName} · ${item.employeeCode}',
                ),
              ),
            ),
          ],
          if (task.wasteMaterials.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const _MiniTitle('Productos de merma'),
            const SizedBox(height: 8),
            ...task.wasteMaterials.map(
              (WorkOrderTaskMaterialItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RowTile(
                  title: item.productName,
                  subtitle: item.areaSqm != null &&
                          item.widthMeters != null &&
                          item.heightMeters != null
                      ? '${_qty(item.qty)} ${item.unitLabel} · ${_qty(item.widthMeters!)} m x ${_qty(item.heightMeters!)} m'
                      : '${_qty(item.qty)} ${item.unitLabel} · ${item.productSku}',
                  tint: const Color(0xFFFFF7ED),
                  accent: const Color(0xFFEA580C),
                ),
              ),
            ),
          ],
          if (task.imagePaths.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Expanded(
                  child: _MiniTitle('Imágenes del trabajo'),
                ),
                if (canManageImages &&
                    task.imagePaths.length > 1 &&
                    onReorderImages != null)
                  TextButton.icon(
                    onPressed: () => _openReorderSheet(context),
                    icon: const Icon(Icons.swap_vert_rounded),
                    label: const Text('Organizar'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: task.imagePaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  final File file = File(task.imagePaths[index]);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WorkOrderTaskImageViewerPage(
                            imagePaths: List<String>.of(task.imagePaths),
                            initialIndex: index,
                            canDelete: canManageImages && onDeleteImage != null,
                            onDeleteImage: onDeleteImage,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 104,
                        height: 104,
                        color: const Color(0xFFE2E8F0),
                        child: file.existsSync()
                            ? Image.file(file, fit: BoxFit.cover)
                            : const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF64748B),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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

  String _dateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  Future<void> _openReorderSheet(BuildContext context) async {
    final Future<bool> Function(List<String> imagePaths)? onReorderImages =
        this.onReorderImages;
    if (onReorderImages == null) {
      return;
    }
    final List<String>? reordered = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.78,
        child: WorkOrderTaskImagesReorderSheet(
          imagePaths: task.imagePaths,
        ),
      ),
    );
    if (reordered == null) {
      return;
    }
    await onReorderImages(reordered);
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.title,
    required this.subtitle,
    this.tint = const Color(0xFFF8FAFC),
    this.accent = const Color(0xFF0F172A),
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }
}
