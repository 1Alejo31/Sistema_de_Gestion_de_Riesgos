import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_account.dart';
import '../services/users_service.dart';
import 'auth_providers.dart';

final usersServiceProvider = Provider<UsersService>(
  (ref) => UsersService(ref.read(authControllerProvider)),
  dependencies: [authControllerProvider],
);

final userAccountsProvider = FutureProvider.autoDispose<List<UserAccount>>(
  (ref) => ref.watch(usersServiceProvider).listUsers(),
  dependencies: [usersServiceProvider],
  retry: (retryCount, error) => null,
);
