import '../../models/photo_group.dart';

abstract class PhotoGroupRepository {
  Future<List<PhotoGroup>> getAll();
  Future<PhotoGroup?> getById(String id);
  Future<void> upsert(PhotoGroup group);
  Future<void> delete(String id);
}
