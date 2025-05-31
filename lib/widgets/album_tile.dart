import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AlbumTile extends StatefulWidget {
  final String title;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final Widget Function(Widget child) onReorderHandle;

  const AlbumTile({
    Key? key,
    required this.title,
    required this.onRename,
    required this.onDelete,
    required this.onReorderHandle,
  }) : super(key: key);

  @override
  State<AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile> {
  bool _hovered = false;

  // На яких платформах вважаємо «мобільними»
  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    // Показ меню, якщо мобільна, або якщо hover на десктопі
    final showMenu = _isMobile || _hovered;
    // Показ ручки лише на десктопі при hover
    final showHandle = !_isMobile && _hovered;

    return MouseRegion(
      // onEnter/Exit реагують тільки на не‐мобільних
      onEnter: !_isMobile ? (_) => setState(() => _hovered = true) : null,
      onExit:  !_isMobile ? (_) => setState(() => _hovered = false) : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: showHandle ? 6 : 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ручка для перетягування (ПК лише)
              if (showHandle)
                widget.onReorderHandle(
                  const Icon(Icons.drag_handle, color: Colors.grey),
                )
              else if (!_isMobile)
                const SizedBox(width: 24),

              const SizedBox(width: 12),

              // Сам заголовок
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Меню з трьома крапками
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: showMenu ? Colors.grey : Colors.transparent,
                ),
                onSelected: (v) {
                  if (v == 'rename') widget.onRename();
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'rename', child: Text('rename'.tr())),
                  PopupMenuItem(value: 'delete', child: Text('delete'.tr())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
