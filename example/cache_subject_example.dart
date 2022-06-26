import 'dart:async';

import 'package:cache_subject/cache_subject.dart';

abstract class Identifiable<T> {
  abstract final T id;
}

abstract class UserIdentity implements Identifiable<int> {
  abstract final List<UserIdentity> friends;
}

class User implements UserIdentity {
  @override
  final int id;

  final String name;

  @override
  final List<User> friends;

  @override
  String toString() => "User#$id($name, $friends)";
  User(this.id, this.name, this.friends);
}

class Cache {
  final userStream = CacheSubject<User, int>((u) => u.id);

  late final StreamSubscription<User> _userUpdater;

  Cache() {
    _userUpdater = userStream.listenAll((user) {
      /// Due to built-in equality check, 
      /// circular relations is not a problem
      /// until there is data inconsistency
      userStream.addAll(user.friends);
    });
  }

  void dispose() {
    userStream.dispose();
    _userUpdater.cancel();
  }
}

class UserRepository {
  final Cache cache;

  UserRepository(this.cache);

  Future<UserIdentity> updateUser(User updatedUser) async {
    await Future.delayed(Duration(milliseconds: 200)); // make http call
    cache.userStream.add(updatedUser);
    return updatedUser;
  }

  Future<UserIdentity> getMe() async {
    final cached = cache.userStream.valueOrNull(1);
    if (cached != null) {
      return cached;
    }

    final user = await Future.delayed(
      Duration(milliseconds: 200),
      () => User(
        1,
        "Alexander",
        const [],
      ),
    ); // make http call
    cache.userStream.add(user);
    return user;
  }
}

void main() async {
  final cache = Cache();
  final repository = UserRepository(cache);

  final me = await repository.getMe();
  cache.userStream.listen(
    key: me.id,
    (data) {
      print("Me updated to $data");
    },
  );

  // Update another user
  final john = await repository.updateUser(User(2, "John", const []));
  cache.userStream.listen(
    key: john.id,
    (data) {
      print("User updated to $data");
    },
  );

  await repository.updateUser(User(me.id, "Alex", const []));

  // make friends with Alex (who is Alexander now)
  final newJohn = User(2, "John", []);
  newJohn.friends.add(User(me.id, "Alexander", [newJohn]));

  await repository.updateUser(newJohn);

  await Future.delayed(Duration(seconds: 3));
  cache.dispose();
}
