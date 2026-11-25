class _Navigator {
  String? get platform => null;
}

class _Window {
  final navigator = _Navigator();
}

final window = _Window();
