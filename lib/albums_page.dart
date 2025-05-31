import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_data.dart';
import '../widgets/album_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/photo_tile.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  late final String _userId;

  /// ID та заголовок вибраного альбому (null — показати галерею)
  String? _selectedAlbumId;
  String? _selectedAlbumTitle;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _addAlbum() async {
    if (_userId.isEmpty) return;
    String title = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('new_album'.tr()),
        content: TextField(
          decoration: InputDecoration(labelText: 'album_name'.tr()),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('create'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || title.trim().isEmpty) return;
    await _db.collection('users').doc(_userId).collection('albums').add({
      'title': title.trim(),
      'order': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _renameAlbum(String id, String current) async {
    String name = current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: current);
        return AlertDialog(
          title: Text('rename_album'.tr()),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'new_title'.tr()),
            onChanged: (v) => name = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
    if (ok != true || name.trim().isEmpty) return;
    await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(id)
        .update({'title': name.trim()});
  }

  Future<void> _deleteAlbum(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_album_question'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('no'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('albums')
          .doc(id)
          .delete();
    }
  }

  Future<void> _reorderAlbums(
    int oldIndex,
    int newIndex,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final ids = docs.map((d) => d.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final batch = _db.batch();
    final col = _db.collection('users').doc(_userId).collection('albums');
    for (var i = 0; i < ids.length; i++) {
      batch.update(col.doc(ids[i]), {'order': i});
    }
    await batch.commit();
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    if (_userId.isEmpty) return;
    final picked = await _picker.pickImage(source: source, maxWidth: 1080);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref('users/$_userId/photos/$fileName.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(_userId).collection('photos').add({
      'url': url,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _movePhotoToAlbum(PhotoData photo, String destAlbumId) async {
    // 1) Створюємо новий документ у вибраному альбомі
    final newDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(destAlbumId)
        .collection('photos')
        .add({'url': photo.url, 'createdAt': FieldValue.serverTimestamp()});

    // 2) Копіюємо коментарі з кореневої галереї
    final oldComments = await _db
        .collection('users')
        .doc(_userId)
        .collection('photos')
        .doc(photo.id)
        .collection('comments')
        .get();
    for (var c in oldComments.docs) {
      await newDoc.collection('comments').add(c.data());
      await _db
          .collection('users')
          .doc(_userId)
          .collection('photos')
          .doc(photo.id)
          .collection('comments')
          .doc(c.id)
          .delete();
    }

    // 3) Видаляємо старий документ з галереї
    await _db
        .collection('users')
        .doc(_userId)
        .collection('photos')
        .doc(photo.id)
        .delete();
  }

  /// Перемістити фото між альбомами разом з коментарями
  Future<void> _movePhotoBetweenAlbums(
    PhotoData photo,
    String destAlbumId,
  ) async {
    final fromAlbumId = _selectedAlbumId!;
    final newDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(destAlbumId)
        .collection('photos')
        .add({'url': photo.url, 'createdAt': FieldValue.serverTimestamp()});

    final oldComments = await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(fromAlbumId)
        .collection('photos')
        .doc(photo.id)
        .collection('comments')
        .get();
    for (var c in oldComments.docs) {
      await newDoc.collection('comments').add(c.data());
      await _db
          .collection('users')
          .doc(_userId)
          .collection('albums')
          .doc(fromAlbumId)
          .collection('photos')
          .doc(photo.id)
          .collection('comments')
          .doc(c.id)
          .delete();
    }

    await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(fromAlbumId)
        .collection('photos')
        .doc(photo.id)
        .delete();
  }

  /// Повернути фото з альбому в галерею разом з коментарями
  Future<void> _movePhotoToGallery(PhotoData photo, String fromAlbumId) async {
    final newDoc = await _db
        .collection('users')
        .doc(_userId)
        .collection('photos')
        .add({'url': photo.url, 'createdAt': FieldValue.serverTimestamp()});

    final oldComments = await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(fromAlbumId)
        .collection('photos')
        .doc(photo.id)
        .collection('comments')
        .get();
    for (var c in oldComments.docs) {
      await newDoc.collection('comments').add(c.data());
      await _db
          .collection('users')
          .doc(_userId)
          .collection('albums')
          .doc(fromAlbumId)
          .collection('photos')
          .doc(photo.id)
          .collection('comments')
          .doc(c.id)
          .delete();
    }

    await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .doc(fromAlbumId)
        .collection('photos')
        .doc(photo.id)
        .delete();
  }

  Future<void> _confirmDeletePhoto(String photoId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_photo_title'.tr()),
        content: Text('delete_photo_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('no'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final col = _selectedAlbumId != null
        ? _db
              .collection('users')
              .doc(_userId)
              .collection('albums')
              .doc(_selectedAlbumId!)
              .collection('photos')
        : _db.collection('users').doc(_userId).collection('photos');

    await col.doc(photoId).delete();
  }

  /// Відкриває bottom sheet з чатом коментарів для даного фото
  Future<void> _showCommentsSheet(String photoId, [String? albumId]) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String newComment = '';
        // обчислюємо куди писати/читати: у альбомі чи в галереї
        final commentsCol = (albumId != null)
            ? _db
                  .collection('users')
                  .doc(_userId)
                  .collection('albums')
                  .doc(albumId)
                  .collection('photos')
                  .doc(photoId)
                  .collection('comments')
            : _db
                  .collection('users')
                  .doc(_userId)
                  .collection('photos')
                  .doc(photoId)
                  .collection('comments');
        print('🛠 comments go to: ${commentsCol.path}');

        return Padding(
          // Щоб підняти sheet вище клавіатури
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'comments_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Список існуючих коментарів
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: commentsCol.orderBy('createdAt').snapshots(),
                    builder: (ctx2, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return Center(child: Text('no_comments'.tr()));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (ctx3, i) {
                          final data = docs[i].data() as Map<String, dynamic>;

                          // Зчитуємо Timestamp, потім формат — без секунд
                          final tsField = data['createdAt'];
                          String dateStr;
                          if (tsField is Timestamp) {
                            final dt = tsField.toDate();
                            // Форматуємо вручну без секунд
                            final twoDigits = (int n) =>
                                n.toString().padLeft(2, '0');
                            final h = twoDigits(dt.hour);
                            final m = twoDigits(dt.minute);
                            dateStr =
                                '${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)}  $h:$m';
                          } else {
                            dateStr = 'зараз';
                          }

                          return ListTile(
                            title: Text(data['text'] as String),
                            subtitle: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            // Ось воно — меню з трьома крапочками
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                              onSelected: (choice) async {
                                if (choice == 'edit') {
                                  // викликати діалог редагування
                                  final newText = await showDialog<String>(
                                    context: ctx,
                                    builder: (dctx) {
                                      var tmp = data['text'] as String;
                                      return AlertDialog(
                                        title: Text('edit_comment'.tr()),
                                        content: TextField(
                                          controller: TextEditingController(
                                            text: tmp,
                                          ),
                                          onChanged: (v) => tmp = v,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dctx),
                                            child: Text('cancel'.tr()),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(dctx, tmp),
                                            child: Text('save'.tr()),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (newText != null &&
                                      newText.trim().isNotEmpty) {
                                    await commentsCol.doc(docs[i].id).update({
                                      'text': newText.trim(),
                                    });
                                  }
                                } else if (choice == 'delete') {
                                  // викликати підтвердження видалення
                                  final ok = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dctx) => AlertDialog(
                                      title: Text('delete_comment_title'.tr()),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dctx, false),
                                          child: Text('no'.tr()),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(dctx, true),
                                          child: Text('yes'.tr()),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await commentsCol.doc(docs[i].id).delete();
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('edit'.tr()),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('delete'.tr()),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(height: 1),
                // Поле вводу нового коментаря
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => newComment = v,
                          decoration: InputDecoration(
                            hintText: 'comment_input_hint'.tr(),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (newComment.trim().isEmpty) return;
                          await commentsCol.add({
                            'text': newComment.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                            'authorId': _userId,
                          });
                          newComment = '';
                          // Щоб очистити поле, закрийте і заново відкрийте sheet
                          Navigator.pop(ctx);
                          _showCommentsSheet(photoId);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchAlbumList() async {
    final list = await _db
        .collection('users')
        .doc(_userId)
        .collection('albums')
        .orderBy('order')
        .get()
        .then(
          (snap) => snap.docs.map((d) {
            final rawTitle = d.data()['title'];
            final title = rawTitle is String
                ? rawTitle
                : (rawTitle[context.locale.languageCode] ??
                          rawTitle.values.first)
                      as String;
            return {'id': d.id, 'title': title};
          }).toList(),
        );

    // вставляємо першим елементом “Галерея”
    list.insert(0, {'id': 'gallery', 'title': tr('gallery_label')});
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Розраховуємо, чи мобільний екран (<600px), і кількість стовпців у GridView
    final isMobile = MediaQuery.of(context).size.width < 600;
    final gridCount = isMobile ? 2 : 4;
    final isAlbumOpen = _selectedAlbumId != null;

    // 2. Ліва панель: заголовок + список альбомів
    final albumListPanel = Flexible(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок "My Albums" + кнопка додавання
          Row(
            children: [
              Expanded(
                child: Text(
                  'my_albums'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: _addAlbum),
            ],
          ),
          const SizedBox(height: 8),
          // Список альбомів з можливістю перетягувати
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('users')
                  .doc(_userId)
                  .collection('albums')
                  .orderBy('order')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Немає альбомів'));
                }
                return ReorderableListView.builder(
                  itemCount: docs.length,
                  // На мобільних можна довгим тапом по будь-якому місцю перетягувати,
                  // а на десктопі — тільки через drag-хендл
                  buildDefaultDragHandles: isMobile,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onReorder: (oldIndex, newIndex) =>
                      _reorderAlbums(oldIndex, newIndex, docs),
                  itemBuilder: (ctx, i) {
                    final album = docs[i];
                    final rawTitle = album.data()['title'];
                    final title = rawTitle is String
                        ? rawTitle
                        : (rawTitle[context.locale.languageCode] ??
                                  rawTitle.values.first)
                              as String;

                    // DragTarget дозволяє скидати фото на альбом
                    return DragTarget<PhotoData>(
                      key: ValueKey(album.id),
                      onWillAccept: (_) => true,
                      onAccept: (photo) => _movePhotoToAlbum(photo, album.id),
                      builder: (context, candidate, rejected) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAlbumId = album.id;
                              _selectedAlbumTitle = title;
                            });
                          },
                          child: AlbumTile(
                            key: ValueKey(album.id),
                            title: title,
                            onRename: () => _renameAlbum(album.id, title),
                            onDelete: () => _deleteAlbum(album.id),
                            onReorderHandle: (child) =>
                                ReorderableDragStartListener(
                                  index: i,
                                  child: child,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    // 3. Права панель: кнопка назад / додавання фото + сітка фото
    final photosPanel = Flexible(
      flex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Якщо альбом відкрито — показати кнопку назад і заголовок
          if (isAlbumOpen)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _selectedAlbumId = null;
                    _selectedAlbumTitle = null;
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedAlbumTitle ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          // Інакше — кнопка завантаження з галереї
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: Text('gallery_label'.tr()),
                onPressed: () => _uploadPhoto(ImageSource.gallery),
              ),
            ),
          const SizedBox(height: 8),
          // Сама сітка фото
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: isAlbumOpen
                  ? _db
                        .collection('users')
                        .doc(_userId)
                        .collection('albums')
                        .doc(_selectedAlbumId!)
                        .collection('photos')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : _db
                        .collection('users')
                        .doc(_userId)
                        .collection('photos')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final photos = snap.data!.docs;
                if (photos.isEmpty) {
                  return const Center(child: Text('Немає фото'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        gridCount, // <- Адаптивна кількість стовпців
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) {
                    final doc = photos[i];
                    final url = doc.data()['url'] as String?;
                    if (url == null) return const SizedBox();
                    return AspectRatio(
                      aspectRatio: 1,
                      child: PhotoTile(
                        photo: PhotoData(id: doc.id, url: url),
                        onMove: (photo, destId) async {
                          if (_selectedAlbumId == null) {
                            await _movePhotoToAlbum(photo, destId);
                          } else if (destId == 'gallery') {
                            await _movePhotoToGallery(photo, _selectedAlbumId!);
                          } else {
                            await _movePhotoBetweenAlbums(photo, destId);
                          }
                        },
                        onDelete: () => _confirmDeletePhoto(doc.id),
                        onComment: () =>
                            _showCommentsSheet(doc.id, _selectedAlbumId),
                        fetchAlbums: _fetchAlbumList,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    // 4. Повертаємо або Row (для ширших екранів) або Column (мобільні)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? Column(
              children: [
                albumListPanel,
                const SizedBox(height: 24),
                photosPanel,
              ],
            )
          : Row(
              children: [
                albumListPanel,
                const SizedBox(width: 24),
                photosPanel,
              ],
            ),
    );
  }

  Widget buildPhotoCell(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(url, fit: BoxFit.cover),
  );
}
