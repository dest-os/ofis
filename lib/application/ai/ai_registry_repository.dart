import '../../domain/ai/ai_model_profile.dart';

abstract interface class AiRegistryRepository {
  List<AiModelProfile> getAll();
  AiModelProfile? findById(String id);
  void upsert(AiModelProfile profile);
}
