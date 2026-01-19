import 'dart:convert';

import 'package:flutter/services.dart';

class JsonLoader {
  Future<Map<String, dynamic>> loadJson(String path) async {
    final String response = await rootBundle.loadString(path);
    return json.decode(response);
  }

  Future<List<dynamic>> loadJsonList(String path) async {
    final String response = await rootBundle.loadString(path);
    return json.decode(response);
  }
}
