import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organization.dart';
import '../services/organizations_service.dart';
import 'auth_providers.dart';

final organizationsServiceProvider = Provider<OrganizationsService>(
  (ref) => OrganizationsService(ref.read(authControllerProvider)),
  dependencies: [authControllerProvider],
);

final organizationsProvider = FutureProvider.autoDispose<List<Organization>>(
  (ref) {
    final session = ref.watch(
      authStateProvider.select(
        (state) => (
          state.identity?.id,
          state.isAuthenticated,
          state.passwordChangeRequired,
        ),
      ),
    );
    if (!session.$2 || session.$3) return Future.value(const []);
    return ref.watch(organizationsServiceProvider).listOrganizations();
  },
  dependencies: [organizationsServiceProvider, authStateProvider],
  retry: (retryCount, error) => null,
);

final selectedOrganizationIdProvider =
    NotifierProvider<SelectedOrganizationId, String?>(
      SelectedOrganizationId.new,
      dependencies: [authStateProvider],
    );

class SelectedOrganizationId extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authStateProvider.select((state) => state.identity?.id));
    return null;
  }

  void select(String id) => state = id;
}

final selectedOrganizationProvider = Provider<Organization?>((ref) {
  final id = ref.watch(selectedOrganizationIdProvider);
  final organizations = ref.watch(organizationsProvider).asData?.value ?? [];
  for (final organization in organizations) {
    if (organization.id == id) return organization;
  }
  return null;
}, dependencies: [selectedOrganizationIdProvider, organizationsProvider]);
