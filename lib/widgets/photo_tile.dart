// lib/widgets/photo_tile.dart

import 'package:flutter/material.dart';
import '../models/photo_data.dart';

/// Простий віджет фото з постійним меню знизу та подвійним натисканням для перегляду
class PhotoTile extends StatelessWidget {
  final PhotoData photo;
  final bool isDraggable;
  final Future<void> Function(PhotoData, String) onMove;
  final VoidCallback onDelete;
  final VoidCallback onComment;
  final Future<List<Map<String, String>>> Function() fetchAlbums;

  const PhotoTile({
    Key? key,
    required this.photo,
    this.isDraggable = true,
    required this.onMove,
    required this.onDelete,
    required this.onComment,
    required this.fetchAlbums,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Фото з double-tap для перегляду
        Expanded(
          child: GestureDetector(
            onDoubleTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: InteractiveViewer(child: Image.network(photo.url)),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photo.url,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        // Постійне меню знизу
        ClipRect(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2),
            color: Colors.black26,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.drive_file_move, color: Colors.white),
                  onPressed: () async {
                    final albums = await fetchAlbums();
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Перемістити до'),
                        children: albums.map((a) {
                          return SimpleDialogOption(
                            child: Text(a['title']!),
                            onPressed: () => Navigator.pop(ctx, a['id']),
                          );
                        }).toList(),
                      ),
                    );
                    if (selected != null) await onMove(photo, selected);
                  },
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.comment, color: Colors.white),
                  onPressed: onComment,
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
