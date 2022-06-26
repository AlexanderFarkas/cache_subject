import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';

class NoValueException<T, K> implements Exception {
  final String message;

  NoValueException(this.message);

  @override
  String toString() {
    return "NoValueException(CacheSubject<$T,$K>): $message";
  }
}

typedef Equals<T> = bool Function(T? cached, T newValue);

class CacheSubject<T, K> {
  static bool defaultEquals<T>(T? cached, T newValue) => cached == newValue;

  final StreamController<T> _controller;
  final K Function(T) _key;

  final Equals<T> _equals;
  final _cache = HashMap<K, T>();

  T value(K key) {
    if (hasValue(key)) {
      return _cache[key] as T;
    }
    throw NoValueException<T, K>("Value with key $key doesn't exist");
  }

  T? valueOrNull(K key) => _cache[key];

  bool hasValue(K key) => _cache.containsKey(key);

  CacheSubject(this._key, {Equals<T>? equals})
      : _equals = equals ?? defaultEquals<T>,
        _controller = StreamController.broadcast();

  Stream<T> stream(K key) {
    final stream = hasValue(key)
        ? _controller.stream.startWith(_value(key))
        : _controller.stream;

    return stream.where((event) => _key(event) == key);
  }

  void add(T value) {
    if (_equals(_cache[_key(value)], value)) {
      return;
    }

    _cache[_key(value)] = value;
    _controller.add(value);
  }

  void addAll(Iterable<T> values) {
    for (final value in values) {
      add(value);
    }
  }

  void remove(K key) => _cache.remove(key);

  StreamSubscription<T> listen(void Function(T data) onData, {required K key}) {
    return stream(key).listen(onData);
  }

  StreamSubscription<T> listenAll(void Function(T data) onData) {
    return _controller.stream.listen(onData);
  }

  Future<void> dispose() {
    _cache.clear();
    return _controller.close();
  }

  /// Should be used only after hasValue;
  T _value(K key) => _cache[key] as T;
}
