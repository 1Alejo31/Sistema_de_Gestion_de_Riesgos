import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/company_information_service.dart';
import 'auth_providers.dart';

final companyInformationServiceProvider = Provider<CompanyInformationService>(
  (ref) => CompanyInformationService(ref.read(authControllerProvider)),
  dependencies: [authControllerProvider],
);
