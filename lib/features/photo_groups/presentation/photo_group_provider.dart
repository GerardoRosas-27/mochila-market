import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/photo_group_repository.dart';
import '../../../core/models/photo_group.dart';

class PhotoGroupNotifier extends StateNotifier<List<PhotoGroup>> {
  PhotoGroupNotifier(this._repo) : super(const []) {
    _load();
  }

  final PhotoGroupRepository _repo;
  final _uuid = const Uuid();

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> reload() async {
    state = await _repo.getAll();
  }

  Future<PhotoGroup> create({
    required String name,
    List<String> photoPaths = const [],
  }) async {
    final group = PhotoGroup(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Grupo de fotos' : name.trim(),
      photoPaths: photoPaths,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(group);
    await reload();
    return group;
  }

  Future<void> update(PhotoGroup group) async {
    await _repo.upsert(group);
    await reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await reload();
  }

  PhotoGroup? byId(String? id) {
    if (id == null) return null;
    try {
      return state.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}

final photoGroupProvider =
    StateNotifierProvider<PhotoGroupNotifier, List<PhotoGroup>>((ref) {
  return PhotoGroupNotifier(ref.watch(photoGroupRepositoryProvider));
});
