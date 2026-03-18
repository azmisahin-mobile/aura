import '../entities/aura_state_enum.dart';

abstract class IContextEngine {
  Stream<AuraState> get stateStream;
  Future<void> initializePermissions();
}