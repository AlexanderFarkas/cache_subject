import 'package:cache_subject/cache_subject.dart';
import 'package:test/test.dart';

class Entity {
  final int id;
  final String name;
  Entity(this.id, this.name);

  @override
  int get hashCode => Object.hashAll([id, name]);

  @override
  operator ==(Object? other) =>
      other is Entity && id == other.id && name == other.name;
}

void main() {
  group('A group of tests', () {
    late CacheSubject<Entity?, int> subject;

    setUp(() => subject = CacheSubject<Entity, int>((e) => e.id));
    tearDown(() => subject.dispose());

    test('Usage', () {
      subject.add(Entity(2, "Alexander"));
      subject.add(Entity(1, "Alex"));

      expect(
        subject.stream(2),
        emitsInOrder([Entity(2, "Alexander"), Entity(2, "Sasha")]),
      );

      subject.add(Entity(2, "Sasha"));

      expect(subject.stream(1), emitsInOrder([Entity(1, "Alex")]));
      expect(subject.stream(2), emitsInOrder([Entity(2, "Sasha")]));
    });

    test('Value', () {
      expect(() => subject.value(1), throwsA(TypeMatcher<NoValueException>()));
      subject.add(Entity(1, "Alex"));
      expect(subject.value(1), equals(Entity(1, "Alex")));
      expect(() => subject.value(2), throwsA(TypeMatcher<NoValueException>()));
    });

    test('ValueOrNull', () {
      expect(subject.valueOrNull(1), equals(null));
      subject.add(Entity(1, "Alex"));
      expect(subject.value(1), equals(Entity(1, "Alex")));
      expect(subject.valueOrNull(2), equals(null));
    });

    test('Stream after removal', () {
      subject.add(Entity(1, "Alex"));
      expect(subject.stream(1), emitsInOrder([Entity(1, "Alex")]));
      subject.remove(1);
      expect(() => subject.value(1), throwsA(TypeMatcher<NoValueException>()));
    });
  });
}
