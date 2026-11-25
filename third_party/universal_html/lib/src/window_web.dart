import 'package:web/web.dart' as web;

class _Navigator {
  String? get platform => web.window.navigator.platform;
}

class _Window {
  final navigator = _Navigator();
}

final window = _Window();
