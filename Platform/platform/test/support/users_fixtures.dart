import 'package:http/http.dart' as http;

import 'auth_fixtures.dart';

const accountItems = [
  {
    'id': '184ba60e-4883-4b77-a1c3-9e2c3f7b568d',
    'email': 'demo.observer@sgsst.invalid',
    'roles': <String>[],
    'status': 'ACTIVE',
    'scope': 'GLOBAL',
    'createdAt': '2026-10-12T21:54:52.192Z',
  },
  {
    'id': '22001202-81c0-4e93-bb7e-75b19da36eff',
    'email': 'demo.consultant@sgsst.invalid',
    'roles': ['SUPER_ADMIN'],
    'status': 'ACTIVE',
    'scope': 'GLOBAL',
    'createdAt': '2026-10-12T21:54:52.192Z',
  },
];

http.Response usersResponse({List<Object?> items = accountItems}) =>
    jsonResponse({
      'data': {'items': items},
    }, 200);
