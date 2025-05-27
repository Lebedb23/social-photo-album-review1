import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_data.dart';
import '../widgets/album_tile.dart';
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
        title: const Text('Новий альбом'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Назва альбому'),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Створити'),
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
          title: const Text('Перейменувати альбом'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Нова назва'),
            onChanged: (v) => name = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Зберегти'),
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
        title: const Text('Видалити альбом?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ні'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Так'),
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
        title: const Text('Видалити фото?'),
        content: const Text('Ви дійсно хочете видалити це фото?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ні'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Так'),
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
  Future<void> _showCommentsSheet(String photoId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String newComment = '';
        // Обираємо, з якої колекції читати/писати коментарі
        final commentsCol = (_selectedAlbumId != null)
            // Якщо альбом відкритий — колекція comments в документі фото в альбомі
            ? _db
                  .collection('users')
                  .doc(_userId)
                  .collection('albums')
                  .doc(_selectedAlbumId!)
                  .collection('photos')
                  .doc(photoId)
                  .collection('comments')
            // Інакше — колекція comments в документі фото в головній галереї
            : _db
                  .collection('users')
                  .doc(_userId)
                  .collection('photos')
                  .doc(photoId)
                  .collection('comments');

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
                    'Коментарі',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        return const Center(child: Text('Немає коментарів'));
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
                                        title: Text('Редагувати коментар'),
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
                                            child: Text('Скасувати'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(dctx, tmp),
                                            child: Text('Зберегти'),
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
                                      title: Text('Видалити коментар?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dctx, false),
                                          child: Text('Ні'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(dctx, true),
                                          child: Text('Так'),
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
                                  child: Text('Редагувати'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Видалити'),
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
                          decoration: const InputDecoration(
                            hintText: 'Введіть коментар…',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
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
                          await _db
                              .collection('users')
                              .doc(_userId)
                              .collection('photos')
                              .doc(photoId)
                              .collection('comments')
                              .add({
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
          (snap) => snap.docs
              .map((d) => {'id': d.id, 'title': d.data()['title'] as String})
              .toList(),
        );
    // вставляємо першим елементом “Галерея”
    list.insert(0, {'id': 'gallery', 'title': 'Галерея'});
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isAlbumOpen = _selectedAlbumId != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Мої альбоми',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addAlbum,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection('users')
                        .doc(_userId)
                        .collection('albums')
                        .orderBy('order')
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (snap.hasError)
                        return Center(child: Text('Error: ${snap.error}'));
                      final docs = snap.data!.docs;
                      if (docs.isEmpty)
                        return const Center(child: Text('Немає альбомів'));
                      return ReorderableListView.builder(
                        itemCount: docs.length,
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onReorder: (o, n) => _reorderAlbums(o, n, docs),
                        itemBuilder: (ctx, i) {
                          final album = docs[i];
                          final title = album.data()['title'] as String? ?? '';
                          return DragTarget<PhotoData>(
                            key: ValueKey(album.id),
                            onWillAccept: (_) => true,
                            onAccept: (photo) =>
                                _movePhotoToAlbum(photo, album.id),
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
          ),
          const SizedBox(width: 24),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                // Ось це
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Заголовок ліворуч
                        const Text(
                          '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Кнопка Галерея там, де раніше була Камера
                        TextButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Галерея'),
                          onPressed: () => _uploadPhoto(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
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
                      if (snap.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (snap.hasError)
                        return Center(child: Text('Error: ${snap.error}'));
                      final photos = snap.data!.docs;
                      if (photos.isEmpty)
                        return const Center(child: Text('Немає фото'));
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: photos.length,
                        itemBuilder: (ctx, i) {
                          final doc = photos[i];
                          final url = doc.data()['url'] as String?;
                          if (url == null) return const SizedBox();
                          if (!isAlbumOpen) {
                            return AspectRatio(
                              aspectRatio: 1,
                              child: PhotoTile(
                                photo: PhotoData(id: doc.id, url: url),
                                onMove: (photo, destId) async {
                                  if (_selectedAlbumId == null) {
                                    // із галереї в альбом
                                    await _movePhotoToAlbum(photo, destId);
                                  } else {
                                    // всередині альбому
                                    if (destId == 'gallery') {
                                      await _movePhotoToGallery(
                                        photo,
                                        _selectedAlbumId!,
                                      );
                                    } else {
                                      await _movePhotoBetweenAlbums(
                                        photo,
                                        destId,
                                      );
                                    }
                                  }
                                },
                                onDelete: () => _confirmDeletePhoto(doc.id),
                                onComment: () => _showCommentsSheet(doc.id),
                                fetchAlbums: _fetchAlbumList,
                              ),
                            );
                          }
                          return AspectRatio(
                            aspectRatio: 1,
                            child: PhotoTile(
                              photo: PhotoData(id: doc.id, url: url),
                              onMove: (photo, destId) async {
                                if (_selectedAlbumId == null) {
                                  // Ми в галереї → картинка йде в альбом
                                  await _movePhotoToAlbum(photo, destId);
                                } else {
                                  // Ми в альбомі →
                                  if (destId == 'gallery') {
                                    // повернути у галерею
                                    await _movePhotoToGallery(
                                      photo,
                                      _selectedAlbumId!,
                                    );
                                  } else {
                                    // перемістити між альбомами
                                    await _movePhotoBetweenAlbums(
                                      photo,
                                      destId,
                                    );
                                  }
                                }
                              },
                              onDelete: () => _confirmDeletePhoto(doc.id),
                              onComment: () => _showCommentsSheet(doc.id),
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
          ),
        ],
      ),
    );
  }

  Widget buildPhotoCell(String url) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(url, fit: BoxFit.cover),
  );
}
