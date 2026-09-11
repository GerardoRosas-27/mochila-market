import '../../models/listing_draft.dart';

abstract class DraftRepository {
  Future<List<ListingDraft>> getAll();
  Future<ListingDraft?> getById(String id);
  Future<void> upsert(ListingDraft draft);
  Future<void> delete(String id);
}
