import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/membership_options.dart';
import '../services/memberships_service.dart';
import 'auth_providers.dart';

final membershipsServiceProvider = Provider<MembershipsService>(
  (ref) => MembershipsService(ref.read(authControllerProvider)),
  dependencies: [authControllerProvider],
);
final organizationRolesProvider =
    FutureProvider.autoDispose<List<OrganizationRole>>(
      (ref) => ref.watch(membershipsServiceProvider).roles(),
      dependencies: [membershipsServiceProvider],
      retry: (_, error) => null,
    );
final membershipScopesProvider = FutureProvider.autoDispose
    .family<List<MembershipScope>, String>(
      (ref, id) => ref.watch(membershipsServiceProvider).scopes(id),
      dependencies: [membershipsServiceProvider],
      retry: (_, error) => null,
    );
