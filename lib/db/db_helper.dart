import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member.dart';
import '../models/meal.dart';
import '../models/market.dart';

class DBHelper {
  static const _databaseName = "hostel_manager.db";
  // Updated version to 3 for new schema changes in the market table.
  static const _databaseVersion = 3;

  static const tableMember = 'members';
  static const tableMeals = 'meals';
  static const tableMarket = 'market';
  static const tablePayments = 'payments';
  static const tableAttendance = 'attendance';

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Schema migration handling
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create members table
    await db.execute('''
      CREATE TABLE $tableMember(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        mealPreference TEXT,
        balance REAL DEFAULT 0,
        totalMeals INTEGER DEFAULT 0,
        description TEXT,
        profileImagePath TEXT
      )
    ''');

    // Create meals table
    await db.execute('''
      CREATE TABLE $tableMeals(
        id INTEGER PRIMARY KEY,
        member_id INTEGER,
        date TEXT,
        breakfast INTEGER DEFAULT 0,
        lunch INTEGER DEFAULT 0,
        dinner INTEGER DEFAULT 0,
        FOREIGN KEY (member_id) REFERENCES $tableMember(id)
      )
    ''');

    // Create market table with additional columns and default value for timestamp.
    await db.execute('''
      CREATE TABLE $tableMarket(
        id INTEGER PRIMARY KEY,
        item TEXT,
        amount REAL,
        quantity INTEGER DEFAULT 0,
        date TEXT,
        timestamp INTEGER DEFAULT 0,
        manager_signature TEXT,
        marketer_signature TEXT
      )
    ''');

    // Create payments table
    await db.execute('''
      CREATE TABLE $tablePayments(
        id INTEGER PRIMARY KEY,
        member_id INTEGER,
        amount REAL,
        date TEXT,
        FOREIGN KEY (member_id) REFERENCES $tableMember(id)
      )
    ''');

    // Create attendance table
    await db.execute('''
      CREATE TABLE $tableAttendance(
        id INTEGER PRIMARY KEY,
        member_id INTEGER,
        date TEXT,
        present INTEGER DEFAULT 0,
        FOREIGN KEY (member_id) REFERENCES $tableMember(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // For members table - add columns that might be missing from version 1
      await db.execute('ALTER TABLE $tableMember ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE $tableMember ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE $tableMember ADD COLUMN address TEXT');
      await db
          .execute('ALTER TABLE $tableMember ADD COLUMN mealPreference TEXT');
      await db.execute('ALTER TABLE $tableMember ADD COLUMN description TEXT');
      await db
          .execute('ALTER TABLE $tableMember ADD COLUMN profileImagePath TEXT');
    }
    if (oldVersion < 3) {
      // For market table - add new columns if upgrading from version 2
      await db.execute(
          'ALTER TABLE $tableMarket ADD COLUMN quantity INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE $tableMarket ADD COLUMN timestamp INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE $tableMarket ADD COLUMN manager_signature TEXT');
      await db.execute(
          'ALTER TABLE $tableMarket ADD COLUMN marketer_signature TEXT');
    }
  }

  // Member CRUD operations
  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(tableMember, member.toMap());
  }

  Future<List<Member>> getMembers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableMember);
    return List.generate(maps.length, (i) {
      return Member.fromMap(maps[i]);
    });
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      tableMember,
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      tableMember,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Meal CRUD operations
  Future<int> insertMeal(Meal meal) async {
    final db = await database;
    return await db.insert(tableMeals, meal.toMap());
  }

  Future<List<Meal>> getMeals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableMeals);
    return List.generate(maps.length, (i) {
      return Meal.fromMap(maps[i]);
    });
  }

  // Market CRUD operations
  Future<int> insertMarket(Market market) async {
    final db = await database;
    return await db.insert(tableMarket, market.toMap());
  }

  Future<List<Market>> getMarketItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableMarket);
    return List.generate(maps.length, (i) {
      return Market.fromMap(maps[i]);
    });
  }

  // Payment CRUD operations
  Future<int> insertPayment(int memberId, double amount, String date) async {
    final db = await database;
    return await db.insert(tablePayments, {
      'member_id': memberId,
      'amount': amount,
      'date': date,
    });
  }

  Future<List<Map<String, dynamic>>> getPayments(int memberId) async {
    final db = await database;
    return await db.query(
      tablePayments,
      where: 'member_id = ?',
      whereArgs: [memberId],
    );
  }

  // Attendance CRUD operations
  Future<int> markAttendance(int memberId, String date, int present) async {
    final db = await database;
    return await db.insert(tableAttendance, {
      'member_id': memberId,
      'date': date,
      'present': present,
    });
  }

  Future<List<Map<String, dynamic>>> getAttendance(int memberId) async {
    final db = await database;
    return await db.query(
      tableAttendance,
      where: 'member_id = ?',
      whereArgs: [memberId],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
