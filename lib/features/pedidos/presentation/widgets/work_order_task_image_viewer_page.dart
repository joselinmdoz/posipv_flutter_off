import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WorkOrderTaskImageViewerPage extends StatefulWidget {
  const WorkOrderTaskImageViewerPage({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.canDelete = false,
    this.onDeleteImage,
  });

  final List<String> imagePaths;
  final int initialIndex;
  final bool canDelete;
  final Future<bool> Function(List<String> imagePaths)? onDeleteImage;

  @override
  State<WorkOrderTaskImageViewerPage> createState() =>
      _WorkOrderTaskImageViewerPageState();
}

class _WorkOrderTaskImageViewerPageState
    extends State<WorkOrderTaskImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<String> _imagePaths;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _imagePaths = List<String>.of(widget.imagePaths);
    _currentIndex = widget.initialIndex.clamp(0, _imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: _imagePaths.length,
              onPageChanged: (int index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (_, int index) {
                final File file = File(_imagePaths[index]);
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                          )
                        : const _MissingImageState(),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: <Widget>[
                  _CircleActionButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _CircleActionButton(
                    icon: Icons.share_outlined,
                    onTap: _working ? () {} : _shareCurrent,
                  ),
                  const SizedBox(width: 10),
                  _CircleActionButton(
                    icon: Icons.download_rounded,
                    onTap: _working ? () {} : _saveCurrentCopy,
                  ),
                  if (widget.canDelete &&
                      widget.onDeleteImage != null) ...<Widget>[
                    const SizedBox(width: 10),
                    _CircleActionButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: _working ? () {} : _deleteCurrent,
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0F172A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_imagePaths.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0F172A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(
                        _imagePaths.length,
                        (int index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == _currentIndex ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? const Color(0xFF3B82F6)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCurrent() async {
    final String path = _currentPath;
    if (path.isEmpty) {
      _show('No se encontró la imagen actual.');
      return;
    }
    final File file = File(path);
    if (!file.existsSync()) {
      _show('La imagen ya no existe en esa ruta.');
      return;
    }
    try {
      await Share.shareXFiles(
        <XFile>[XFile(path)],
        text: 'Evidencia del trabajo realizado',
        subject: 'Imagen del pedido',
      );
    } catch (e) {
      _show('No se pudo compartir la imagen: $e');
    }
  }

  Future<void> _saveCurrentCopy() async {
    final String path = _currentPath;
    if (path.isEmpty) {
      _show('No se encontró la imagen actual.');
      return;
    }
    final File source = File(path);
    if (!source.existsSync()) {
      _show('La imagen ya no existe en esa ruta.');
      return;
    }
    setState(() => _working = true);
    try {
      final Directory targetDir = await _resolveEvidenceExportDir();
      final String extension =
          p.extension(path).trim().isEmpty ? '.jpg' : p.extension(path).trim();
      final String fileName =
          'pedido-evidencia-${DateTime.now().millisecondsSinceEpoch}$extension';
      final File copied = await source.copy(p.join(targetDir.path, fileName));
      if (!mounted) {
        return;
      }
      _show('Imagen guardada en:\n${copied.path}');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar la copia: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _deleteCurrent() async {
    final Future<bool> Function(List<String> imagePaths)? onDeleteImage =
        widget.onDeleteImage;
    if (onDeleteImage == null || _imagePaths.isEmpty) {
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar imagen'),
            content: const Text(
              'Esta evidencia dejará de mostrarse en el trabajo realizado. ¿Deseas continuar?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _working = true);
    try {
      final List<String> next = List<String>.of(_imagePaths)
        ..removeAt(_currentIndex);
      final bool deleted = await onDeleteImage(next);
      if (!mounted || !deleted) {
        return;
      }
      if (_imagePaths.length == 1) {
        Navigator.of(context).pop(true);
        return;
      }
      final int nextIndex =
          _currentIndex >= next.length ? next.length - 1 : _currentIndex;
      setState(() {
        _imagePaths = next;
        _currentIndex = nextIndex;
      });
      _pageController.jumpToPage(nextIndex);
      _show('Imagen eliminada.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo eliminar la imagen: $e');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  String get _currentPath {
    if (_imagePaths.isEmpty) {
      return '';
    }
    final int index = _currentIndex.clamp(0, _imagePaths.length - 1);
    return _imagePaths[index];
  }

  Future<Directory> _resolveEvidenceExportDir() async {
    final Directory preferredBase = await _resolveDownloadsBaseDir();
    Directory dir = Directory(
      p.join(preferredBase.path, 'POSIPV', 'Pedidos', 'Evidencias'),
    );
    try {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final Directory docs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docs.path, 'pedidos', 'evidencias'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<Directory> _resolveDownloadsBaseDir() async {
    if (Platform.isAndroid) {
      const List<String> candidates = <String>[
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Descargas',
      ];
      for (final String path in candidates) {
        final Directory dir = Directory(path);
        try {
          if (dir.existsSync()) {
            return dir;
          }
          await dir.create(recursive: true);
          if (dir.existsSync()) {
            return dir;
          }
        } catch (_) {}
      }
      return getApplicationDocumentsDirectory();
    }

    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC0F172A),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MissingImageState extends StatelessWidget {
  const _MissingImageState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF94A3B8),
          size: 56,
        ),
        SizedBox(height: 12),
        Text(
          'No se pudo cargar la imagen.',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
