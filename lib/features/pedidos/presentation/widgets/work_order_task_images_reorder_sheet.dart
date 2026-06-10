import 'dart:io';

import 'package:flutter/material.dart';

class WorkOrderTaskImagesReorderSheet extends StatefulWidget {
  const WorkOrderTaskImagesReorderSheet({
    super.key,
    required this.imagePaths,
  });

  final List<String> imagePaths;

  @override
  State<WorkOrderTaskImagesReorderSheet> createState() =>
      _WorkOrderTaskImagesReorderSheetState();
}

class _WorkOrderTaskImagesReorderSheetState
    extends State<WorkOrderTaskImagesReorderSheet> {
  late List<String> _imagePaths;

  @override
  void initState() {
    super.initState();
    _imagePaths = List<String>.of(widget.imagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Organizar imágenes',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mantén presionado el ícono para mover cada evidencia.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _imagePaths.length,
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                itemBuilder: (_, int index) {
                  final File file = File(_imagePaths[index]);
                  return Container(
                    key: ValueKey<String>(_imagePaths[index]),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFE2E8F0),
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Imagen ${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_imagePaths),
                child: const Text('Guardar orden'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _imagePaths.removeAt(oldIndex);
      _imagePaths.insert(newIndex, item);
    });
  }
}
