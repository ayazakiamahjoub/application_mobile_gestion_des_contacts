import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 3; // ← AUGMENTÉ À 3

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) async {
        await _ensureTablesExist(db);
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await _createUsersTable(db);
    await _createContactsTable(db);
    print('✅ Base de données créée avec les tables users et contacts');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('🔄 Mise à jour de la base: v$oldVersion → v$newVersion');
    
    if (oldVersion < 3) {
      // RECRÉE LA TABLE CONTACTS AVEC userId
      await db.execute('DROP TABLE IF EXISTS contacts');
      await _createContactsTable(db);
      print('✅ Table contacts recréée avec userId');
    }
  }

  Future<void> _ensureTablesExist(Database db) async {
    await _createUsersTableIfNotExists(db);
    await _createContactsTableIfNotExists(db);
  }

  Future<void> _createUsersTableIfNotExists(Database db) async {
    final tableExists = await _tableExists(db, 'users');
    if (!tableExists) {
      await _createUsersTable(db);
      print('✅ Table users créée');
    }
  }

  Future<void> _createContactsTableIfNotExists(Database db) async {
    final tableExists = await _tableExists(db, 'contacts');
    if (!tableExists) {
      await _createContactsTable(db);
      print('✅ Table contacts créée');
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createContactsTable(Database db) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX idx_contacts_userId ON contacts(userId)');
  }

  // ==================== MÉTHODES POUR LES USERS ====================

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // ==================== MÉTHODES POUR LES CONTACTS ====================

  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
  }

  // Lire tous les contacts D'UN UTILISATEUR SPÉCIFIQUE
  Future<List<Contact>> getContacts(int userId) async {
    try {
      final db = await database;
      
      final tableExists = await _tableExists(db, 'contacts');
      if (!tableExists) {
        await _createContactsTable(db);
      }
      
      final result = await db.query(
        'contacts', 
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'firstName ASC'
      );
      print('✅ ${result.length} contacts chargés pour l\'utilisateur $userId');
      return result.map((map) => Contact.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erreur dans getContacts: $e');
      return [];
    }
  }

  Future<Contact?> getContact(int id, int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'contacts',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
      if (result.isNotEmpty) {
        return Contact.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getContact: $e');
      return null;
    }
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [contact.id, contact.userId],
    );
  }

  Future<int> deleteContact(int id, int userId) async {
    final db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Contact>> searchContacts(String query, int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'contacts',
        where: '(firstName LIKE ? OR lastName LIKE ? OR phone LIKE ?) AND userId = ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', userId],
        orderBy: 'firstName ASC',
      );
      return result.map((map) => Contact.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erreur searchContacts: $e');
      return [];
    }
  }

  // MÉTHODE POUR RÉINITIALISER COMPLÈTEMENT LA BASE
  Future<void> resetDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
      }
      final path = join(await getDatabasesPath(), 'app_database.db');
      await deleteDatabase(path);
      _database = null;
      
      await database;
      print('✅ Base de données réinitialisée avec succès');
    } catch (e) {
      print('❌ Erreur resetDatabase: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}