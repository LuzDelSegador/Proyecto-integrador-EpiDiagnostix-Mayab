import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_record.dart';

class PatientLocalRepository {
  static const _dbName = 'epidiagnostix.db';
  static const _table = 'consultas_pendientes';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: 2,
      onCreate: (db, _) => _createTable(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS patient_records');
        await _createTable(db);
      },
    );
  }

  Future<void> _createTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $_table (
      id                 TEXT    PRIMARY KEY,
      fecha_captura      TEXT    NOT NULL,
      nombre_paciente    TEXT    NOT NULL,
      localidad          TEXT    NOT NULL,
      texto_original     TEXT    NOT NULL,
      campos_extraidos   TEXT    NOT NULL,
      sincronizado       INTEGER NOT NULL DEFAULT 0,
      fecha_sincronizado TEXT
    )
  ''');

  Future<String> save(PatientRecord record) async {
    final db = await _database;
    final id = const Uuid().v4();
    await db.insert(_table, {'id': id, ...record.toMap()});
    return id;
  }
}
