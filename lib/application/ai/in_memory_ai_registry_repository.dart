import '../../domain/ai/ai_model_profile.dart';
import 'ai_registry_repository.dart';

class InMemoryAiRegistryRepository implements AiRegistryRepository {
  final Map<String, AiModelProfile> _items = <String, AiModelProfile>{};

  @override
  List<AiModelProfile> getAll() => List.unmodifiable(_items.values);

  @override
  AiModelProfile? findById(String id) => _items[id];

  @override
  void upsert(AiModelProfile profile) {
    _items[profile.id] = profile;
  }
}
