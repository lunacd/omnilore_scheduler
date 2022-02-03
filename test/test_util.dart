import 'package:flutter_test/flutter_test.dart';

class _HasMessage extends Matcher {
  const _HasMessage(String message) : _message = message;

  final String _message;

  @override
  bool matches(item, Map matchState) {
    return item.toString() == _message;
  }

  @override
  Description describe(Description description) {
    return description.add('has message $_message');
  }
}

Matcher hasMessage(String message) => _HasMessage(message);
