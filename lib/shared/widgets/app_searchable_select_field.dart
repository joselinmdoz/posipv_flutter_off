import 'package:flutter/material.dart';

class AppSearchableSelectOption<T> {
  const AppSearchableSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leadingIcon,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? leadingIcon;
  final String? searchText;
}

class AppSearchableSelectField<T> extends StatelessWidget {
  const AppSearchableSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText = 'Seleccionar',
    this.searchHintText = 'Buscar...',
    this.emptyStateText = 'No hay elementos para mostrar.',
    this.emptySearchText = 'No se encontraron resultados.',
    this.enabled = true,
    this.enableSearch = true,
    this.minItemsToSearch = 6,
  });

  final String label;
  final String hintText;
  final String searchHintText;
  final String emptyStateText;
  final String emptySearchText;
  final bool enabled;
  final bool enableSearch;
  final int minItemsToSearch;
  final List<AppSearchableSelectOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final AppSearchableSelectOption<T>? selected = _selectedOption();
    final bool hasOptions = options.isNotEmpty;
    final bool canTap = enabled && hasOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canTap ? () => _openSelector(context, isDark) : null,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: selected == null
                        ? Text(
                            hasOptions ? hintText : emptyStateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                selected.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if ((selected.subtitle ?? '').trim().isNotEmpty)
                                Text(
                                  selected.subtitle!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  AppSearchableSelectOption<T>? _selectedOption() {
    for (final AppSearchableSelectOption<T> option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Future<void> _openSelector(BuildContext context, bool isDark) async {
    final T? selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppSearchableSelectSheet<T>(
        options: options,
        selectedValue: value,
        title: label,
        searchHintText: searchHintText,
        emptyStateText: emptyStateText,
        emptySearchText: emptySearchText,
        enableSearch: enableSearch && options.length >= minItemsToSearch,
        isDark: isDark,
      ),
    );
    if (selected == null) {
      return;
    }
    onChanged(selected);
  }
}

class _AppSearchableSelectSheet<T> extends StatefulWidget {
  const _AppSearchableSelectSheet({
    required this.options,
    required this.selectedValue,
    required this.title,
    required this.searchHintText,
    required this.emptyStateText,
    required this.emptySearchText,
    required this.enableSearch,
    required this.isDark,
  });

  final List<AppSearchableSelectOption<T>> options;
  final T? selectedValue;
  final String title;
  final String searchHintText;
  final String emptyStateText;
  final String emptySearchText;
  final bool enableSearch;
  final bool isDark;

  @override
  State<_AppSearchableSelectSheet<T>> createState() =>
      _AppSearchableSelectSheetState<T>();
}

class _AppSearchableSelectSheetState<T>
    extends State<_AppSearchableSelectSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppSearchableSelectOption<T>> get _visibleOptions {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }
    return widget.options.where((AppSearchableSelectOption<T> option) {
      final String haystack =
          '${option.label} ${option.subtitle ?? ''} ${option.searchText ?? ''}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = widget.isDark;
    final List<AppSearchableSelectOption<T>> visible = _visibleOptions;
    final bool hasQuery = _query.trim().isNotEmpty;
    final String emptyText =
        hasQuery ? widget.emptySearchText : widget.emptyStateText;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        minChildSize: 0.38,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.enableSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (String value) {
                        setState(() => _query = value);
                      },
                      decoration: InputDecoration(
                        hintText: widget.searchHintText,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: hasQuery
                            ? IconButton(
                                tooltip: 'Limpiar',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              emptyText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, int index) {
                            final AppSearchableSelectOption<T> option =
                                visible[index];
                            final bool selected =
                                option.value == widget.selectedValue;
                            const Color selectedColor = Color(0xFF1152D4);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    Navigator.of(context).pop(option.value),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? selectedColor.withValues(alpha: 0.12)
                                        : (isDark
                                            ? const Color(0xFF111B2D)
                                            : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? selectedColor
                                          : (isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      if (option.leadingIcon !=
                                          null) ...<Widget>[
                                        Icon(
                                          option.leadingIcon,
                                          size: 18,
                                          color: selected
                                              ? selectedColor
                                              : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              option.label,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if ((option.subtitle ?? '')
                                                .trim()
                                                .isNotEmpty)
                                              Text(
                                                option.subtitle!.trim(),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF1152D4),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
