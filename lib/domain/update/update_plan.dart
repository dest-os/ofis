import 'update_channel.dart';
class UpdatePlan {
  final String version; final UpdateChannel channel; final String artifactHash; final bool signatureValid; final bool migrationRequired;
  const UpdatePlan({required this.version, required this.channel, required this.artifactHash, required this.signatureValid, required this.migrationRequired});
}
