import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/paciente.dart';
import '../models/patient_record.dart';

class PatientLocalRepository {
  static const _dbName     = 'epidiagnostix.db';
  static const _tPacientes = 'pacientes';
  static const _tConsultas = 'consultas';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: 6,
      onCreate: (db, _) async {
        await _createPacientesTable(db);
        await _createConsultasTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Instalación desde v1/v2: crear tablas nuevas (ya incluyen nombre_normalizado)
          // y migrar datos históricos.
          await _createPacientesTable(db);
          await _createConsultasTable(db);
          await _migrarConsultasPendientes(db);
          await db.execute('DROP TABLE IF EXISTS consultas_pendientes');
          await db.execute('DROP TABLE IF EXISTS patient_records');
          // Salta a los bloques v5/v6 si aplica.
          if (newVersion >= 5) {
            await db.execute('ALTER TABLE $_tConsultas ADD COLUMN latitud REAL');
            await db.execute('ALTER TABLE $_tConsultas ADD COLUMN longitud REAL');
          }
          if (newVersion >= 6) await _agregarColumnasV6(db);
        } else if (oldVersion == 3) {
          // La tabla pacientes existe pero sin nombre_normalizado → ALTER + backfill.
          await db.execute(
            'ALTER TABLE $_tPacientes ADD COLUMN nombre_normalizado TEXT',
          );
          await _poblarNombreNormalizado(db);
          if (newVersion >= 5) {
            await db.execute('ALTER TABLE $_tConsultas ADD COLUMN latitud REAL');
            await db.execute('ALTER TABLE $_tConsultas ADD COLUMN longitud REAL');
          }
          if (newVersion >= 6) await _agregarColumnasV6(db);
        } else if (oldVersion == 4) {
          await db.execute('ALTER TABLE $_tConsultas ADD COLUMN latitud REAL');
          await db.execute('ALTER TABLE $_tConsultas ADD COLUMN longitud REAL');
          if (newVersion >= 6) await _agregarColumnasV6(db);
        } else if (oldVersion == 5) {
          await _agregarColumnasV6(db);
        }
      },
    );
  }

  // Migración v5→v6: identidad de paciente para MS1 (curp, fecha_nacimiento,
  // municipio, lengua_materna, contacto_emergencia) + remote_id de outbox
  // en ambas tablas para el sync contra MS1/MS2.
  Future<void> _agregarColumnasV6(Database db) async {
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN curp TEXT');
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN fecha_nacimiento TEXT');
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN municipio TEXT');
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN lengua_materna TEXT');
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN contacto_emergencia TEXT');
    await db.execute('ALTER TABLE $_tPacientes ADD COLUMN remote_id TEXT');
    await db.execute('ALTER TABLE $_tConsultas ADD COLUMN remote_id TEXT');
  }

  Future<void> _createPacientesTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $_tPacientes (
      id                   TEXT    PRIMARY KEY,
      nombre_completo      TEXT    NOT NULL,
      nombre_normalizado   TEXT,
      sexo                 TEXT,
      comunidad            TEXT,
      primera_visita       TEXT    NOT NULL,
      ultima_visita        TEXT    NOT NULL,
      total_visitas        INTEGER NOT NULL DEFAULT 1,
      sincronizado         INTEGER NOT NULL DEFAULT 0,
      curp                 TEXT,
      fecha_nacimiento     TEXT,
      municipio            TEXT,
      lengua_materna       TEXT,
      contacto_emergencia  TEXT,
      remote_id            TEXT
    )
  ''');

  Future<void> _createConsultasTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $_tConsultas (
      id                 TEXT    PRIMARY KEY,
      paciente_id        TEXT    NOT NULL,
      fecha_captura      TEXT    NOT NULL,
      texto_original     TEXT    NOT NULL,
      campos_extraidos   TEXT    NOT NULL,
      sincronizado       INTEGER NOT NULL DEFAULT 0,
      fecha_sincronizado TEXT,
      latitud            REAL,
      longitud           REAL,
      remote_id          TEXT
    )
  ''');

  // Rellena nombre_normalizado en filas existentes (migración v3→v4).
  Future<void> _poblarNombreNormalizado(Database db) async {
    final rows = await db.query(_tPacientes, columns: ['id', 'nombre_completo']);
    for (final row in rows) {
      await db.update(
        _tPacientes,
        {'nombre_normalizado': _normAcentos(row['nombre_completo'] as String)},
        where:     'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  // Migra filas de consultas_pendientes (v2) agrupándolas por nombre_paciente.
  Future<void> _migrarConsultasPendientes(Database db) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await db.rawQuery('SELECT * FROM consultas_pendientes');
    } catch (_) {
      return; // tabla inexistente → instalación nueva
    }
    if (rows.isEmpty) return;

    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final row in rows) {
      final nombre = (row['nombre_paciente'] as String? ?? '').trim();
      final key    = nombre.isEmpty ? '__anonimo__' : _normAcentos(nombre);
      grupos.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(row));
    }

    for (final grupoRows in grupos.values) {
      grupoRows.sort((a, b) =>
          (a['fecha_captura'] as String).compareTo(b['fecha_captura'] as String));

      final nombreOriginal =
          (grupoRows.first['nombre_paciente'] as String? ?? '').trim();
      final nombre   = nombreOriginal.isEmpty ? 'Paciente Anónimo' : nombreOriginal;
      final localidad = (grupoRows.first['localidad'] as String? ?? '').trim();

      final pacienteId = const Uuid().v4();
      await db.insert(_tPacientes, {
        'id':                 pacienteId,
        'nombre_completo':    nombre,
        'nombre_normalizado': _normAcentos(nombre),
        'sexo':               null,
        'comunidad':          localidad.isEmpty ? null : localidad,
        'primera_visita':     grupoRows.first['fecha_captura'],
        'ultima_visita':      grupoRows.last['fecha_captura'],
        'total_visitas':      grupoRows.length,
        'sincronizado':       0,
      });

      for (final row in grupoRows) {
        await db.insert(_tConsultas, {
          'id':                 const Uuid().v4(),
          'paciente_id':        pacienteId,
          'fecha_captura':      row['fecha_captura'],
          'texto_original':     row['texto_original'] ?? '',
          'campos_extraidos':   row['campos_extraidos'] ?? '{}',
          'sincronizado':       row['sincronizado'] ?? 0,
          'fecha_sincronizado': row['fecha_sincronizado'],
        });
      }
    }
  }

  // ── API pública ────────────────────────────────────────────────────────────

  /// Alta/identidad de paciente para MS1: busca por CURP (no por nombre). Si
  /// ya existe localmente devuelve el registro tal cual (la identidad no se
  /// pisa aquí — para eso está actualizarDatosPaciente). Si no existe, lo crea.
  Future<Paciente> crearOEncontrarPacientePorCurp({
    required String curp,
    required String nombreCompleto,
    required String fechaNacimiento,
    required String sexo,
    String? comunidad,
    required String municipio,
    String? lenguaMaterna,
    String? contactoEmergencia,
  }) async {
    final db = await _database;
    final curpNorm = curp.trim().toUpperCase();

    final rows = await db.query(
      _tPacientes,
      where:     'curp = ?',
      whereArgs: [curpNorm],
      limit:     1,
    );
    if (rows.isNotEmpty) return _pacienteFromRow(rows.first);

    final id      = const Uuid().v4();
    final ahoraIso = DateTime.now().toIso8601String();
    final comunidadVal =
        (comunidad == null || comunidad.trim().isEmpty) ? null : comunidad.trim();
    final row = {
      'id':                  id,
      'nombre_completo':     nombreCompleto,
      'nombre_normalizado':  _normAcentos(nombreCompleto),
      'sexo':                sexo,
      'comunidad':           comunidadVal,
      'primera_visita':      ahoraIso,
      'ultima_visita':       ahoraIso,
      'total_visitas':       0,
      'sincronizado':        0,
      'curp':                curpNorm,
      'fecha_nacimiento':    fechaNacimiento,
      'municipio':           municipio,
      'lengua_materna':      lenguaMaterna,
      'contacto_emergencia': contactoEmergencia,
      'remote_id':           null,
    };
    await db.insert(_tPacientes, row);
    return _pacienteFromRow(row);
  }

  Future<Paciente?> obtenerPorId(String id) async {
    final db = await _database;
    final rows = await db.query(_tPacientes, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _pacienteFromRow(rows.first);
  }

  /// Guarda una consulta vinculada al paciente y registra la visita
  /// (incrementa total_visitas / actualiza ultima_visita del paciente).
  /// Devuelve el UUID local generado.
  Future<String> guardarConsulta(String pacienteId, PatientRecord record) async {
    final db = await _database;
    final id = const Uuid().v4();
    await db.insert(_tConsultas, {
      'id':          id,
      'paciente_id': pacienteId,
      ...record.toMap(),
    });
    await db.rawUpdate(
      'UPDATE $_tPacientes SET total_visitas = total_visitas + 1, ultima_visita = ? WHERE id = ?',
      [record.fechaCaptura.toIso8601String(), pacienteId],
    );
    return id;
  }

  /// Marca un paciente local como sincronizado y guarda el id que devolvió MS1.
  Future<void> marcarPacienteSincronizado(String localId, String remoteId) async {
    final db = await _database;
    await db.update(
      _tPacientes,
      {'sincronizado': 1, 'remote_id': remoteId},
      where:     'id = ?',
      whereArgs: [localId],
    );
  }

  /// Marca una consulta local como sincronizada y guarda el id que devolvió MS2.
  Future<void> marcarConsultaSincronizada(String localId, String remoteId) async {
    final db = await _database;
    await db.update(
      _tConsultas,
      {
        'sincronizado':       1,
        'remote_id':          remoteId,
        'fecha_sincronizado': DateTime.now().toIso8601String(),
      },
      where:     'id = ?',
      whereArgs: [localId],
    );
  }

  /// Pacientes con identidad completa (curp no nulo) pendientes de subir a MS1.
  Future<List<Paciente>> getPacientesPendientesSync() async {
    final db = await _database;
    final rows = await db.query(
      _tPacientes,
      where:     'sincronizado = 0 AND curp IS NOT NULL',
      whereArgs: [],
    );
    return rows.map(_pacienteFromRow).toList();
  }

  /// Consultas pendientes cuyo paciente YA tiene remote_id (MS2 necesita el
  /// paciente_id real del backend, no el id local).
  Future<List<Map<String, dynamic>>> getConsultasPendientesSync() async {
    final db = await _database;
    return db.rawQuery('''
      SELECT c.*, p.remote_id AS paciente_remote_id
      FROM $_tConsultas c
      JOIN $_tPacientes p ON p.id = c.paciente_id
      WHERE c.sincronizado = 0 AND p.remote_id IS NOT NULL
    ''');
  }

  /// Progreso real de sincronización de consultas: total capturadas en este
  /// dispositivo vs. cuántas ya subieron a MS2. Reemplaza el "82/87" fijo del
  /// dashboard — cuenta directamente sobre SQLite, sin llamar a la red.
  Future<SyncStats> getConsultasSyncStats() async {
    final db = await _database;
    final totalRow = await db.rawQuery('SELECT COUNT(*) AS c FROM $_tConsultas');
    final syncRow = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tConsultas WHERE sincronizado = 1',
    );
    return SyncStats(
      total: totalRow.first['c'] as int,
      sincronizadas: syncRow.first['c'] as int,
    );
  }

  /// Cuenta consultas capturadas en la ventana [desde, hasta). Se usa dos
  /// veces desde el dashboard (últimas 24h y las 24h previas) para armar el
  /// indicador "Casos Nuevos (24h)" con su comparación vs. período anterior.
  Future<int> contarConsultasEntre(DateTime desde, DateTime hasta) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tConsultas WHERE fecha_captura >= ? AND fecha_captura < ?',
      [desde.toIso8601String(), hasta.toIso8601String()],
    );
    return rows.first['c'] as int;
  }

  Paciente _pacienteFromRow(Map<String, dynamic> r) => Paciente(
        id:                 r['id'] as String,
        nombreCompleto:     r['nombre_completo'] as String,
        sexo:               r['sexo'] as String?,
        comunidad:          r['comunidad'] as String?,
        primeraVisita:      DateTime.parse(r['primera_visita'] as String),
        ultimaVisita:       DateTime.parse(r['ultima_visita'] as String),
        totalVisitas:       r['total_visitas'] as int,
        sincronizado:       (r['sincronizado'] as int) == 1,
        curp:               r['curp'] as String?,
        fechaNacimiento:    r['fecha_nacimiento'] as String?,
        municipio:          r['municipio'] as String?,
        lenguaMaterna:      r['lengua_materna'] as String?,
        contactoEmergencia: r['contacto_emergencia'] as String?,
        remoteId:           r['remote_id'] as String?,
      );

  /// Devuelve todos los pacientes ordenados por ultima_visita DESC.
  /// Si [filtroNombre] no es null, aplica LIKE sobre nombre_normalizado
  /// (insensible a acentos y mayúsculas).
  Future<List<PacienteConResumen>> getPacientes(String? filtroNombre) async {
    final db      = await _database;
    final hace7d  = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final hace30d = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final tieneF     = filtroNombre != null && filtroNombre.isNotEmpty;
    final filtroNorm = tieneF ? _normAcentos(filtroNombre) : null;

    final sql = '''
      SELECT
        p.*,
        (SELECT COUNT(*) FROM $_tConsultas c
         WHERE c.paciente_id = p.id AND c.fecha_captura >= ?) AS visitas_esta_semana,
        (SELECT COUNT(*) FROM $_tConsultas c
         WHERE c.paciente_id = p.id AND c.fecha_captura >= ?) AS visitas_este_mes
      FROM $_tPacientes p
      ${tieneF ? 'WHERE p.nombre_normalizado LIKE ?' : ''}
      ORDER BY p.ultima_visita DESC
    ''';

    final args = tieneF
        ? [hace7d, hace30d, '%$filtroNorm%']
        : [hace7d, hace30d];

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => PacienteConResumen(
      paciente: _pacienteFromRow(r),
      visitasEstaSemana: r['visitas_esta_semana'] as int,
      visitasEsteMes:    r['visitas_este_mes'] as int,
    )).toList();
  }

  /// Devuelve las consultas de un paciente ordenadas por fecha_captura DESC.
  Future<List<ConsultaResumen>> getConsultasDePaciente(String pacienteId) async {
    final db = await _database;
    final rows = await db.query(
      _tConsultas,
      where:     'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy:   'fecha_captura DESC',
    );

    return rows.map((r) {
      Map<String, dynamic> campos;
      try {
        campos = jsonDecode(r['campos_extraidos'] as String) as Map<String, dynamic>;
      } catch (_) {
        campos = {};
      }
      return ConsultaResumen(
        id:                r['id'] as String,
        pacienteId:        r['paciente_id'] as String,
        fechaCaptura:      DateTime.parse(r['fecha_captura'] as String),
        textoOriginal:     r['texto_original'] as String,
        temperaturaC:      _toDouble(campos['temperatura_c']),
        presionSistolica:  _toInt(campos['presion_sistolica']),
        presionDiastolica: _toInt(campos['presion_diastolica']),
        glucosaMgDl:       _toDouble(campos['glucosa_mg_dl']),
        categoriaSintoma:  campos['categoria_sintoma'] as String?,
        camposExtraidos:   campos,
        sincronizado:      (r['sincronizado'] as int) == 1,
        latitud:           _toDouble(r['latitud']),
        longitud:          _toDouble(r['longitud']),
      );
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Normaliza un nombre para comparación: sin acentos, minúsculas, espacios colapsados.
  // "María López" → "maria lopez", "JOSE  PEREZ" → "jose perez"
  static String _normAcentos(String s) {
    var r = s.trim().toLowerCase();
    const Map<String, String> reemplazos = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n',
    };
    for (final entry in reemplazos.entries) {
      r = r.replaceAll(entry.key, entry.value);
    }
    return r.replaceAll(RegExp(r'\s+'), ' ');
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());
}

class SyncStats {
  final int total;
  final int sincronizadas;

  const SyncStats({required this.total, required this.sincronizadas});

  double get progreso => total == 0 ? 1.0 : sincronizadas / total;
}
