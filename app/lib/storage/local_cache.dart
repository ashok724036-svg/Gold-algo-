import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'local_cache.g.dart';

class CachedCandles extends Table {
  TextColumn get symbol => text()();
  TextColumn get timeframe => text()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get open => real()();
  RealColumn get high => real()();
  RealColumn get low => real()();
  RealColumn get close => real()();
  RealColumn get volume => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {symbol, timeframe, timestamp};
}

@DriftDatabase(tables: [CachedCandles])
class LocalCache extends _$LocalCache {
  LocalCache() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<CachedCandle>> recentCandles(String timeframe, {int limit = 200}) {
    return (select(cachedCandles)
          ..where((row) => row.timeframe.equals(timeframe))
          ..orderBy([(row) => OrderingTerm.desc(row.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<void> saveCandles(Iterable<CachedCandlesCompanion> rows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedCandles, rows.toList());
    });
  }

  Future<void> prune() async {
    await (delete(cachedCandles)
          ..where((row) => row.timestamp.isSmallerThanValue(
                DateTime.now().subtract(const Duration(days: 30)),
              )))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/goldscalper_cache.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}