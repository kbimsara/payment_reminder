import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment.dart';
import '../models/loan.dart';

class DatabaseHelper {
  static const _databaseName = 'payment_reminder.db';
  static const _databaseVersion = 1;

  static const tablePayments = 'payments';
  static const tableLoans = 'loans';
  static const tablePaymentStatus = 'payment_status';

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDay INTEGER NOT NULL,
        category TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 1,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        colorHex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLoans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        lenderName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        monthlyAmount REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        paidMonths INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        interestRate REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePaymentStatus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paymentId INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        paidDate TEXT,
        FOREIGN KEY (paymentId) REFERENCES $tablePayments (id) ON DELETE CASCADE,
        UNIQUE(paymentId, year, month)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
  }

  // ==================== PAYMENT CRUD ====================

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert(
      tablePayments,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePayments,
      orderBy: 'dueDay ASC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getActivePayments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePayments,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'dueDay ASC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<Payment?> getPaymentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      tablePayments,
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    await db.delete(
      tablePaymentStatus,
      where: 'paymentId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> togglePaymentActive(int id, bool isActive) async {
    final db = await database;
    return await db.update(
      tablePayments,
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PAYMENT STATUS CRUD ====================

  Future<Map<int, bool>> getPaymentStatusForMonth(int year, int month) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePaymentStatus,
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    final Map<int, bool> statusMap = {};
    for (final map in maps) {
      statusMap[map['paymentId'] as int] = (map['isPaid'] as int) == 1;
    }
    return statusMap;
  }

  Future<void> setPaymentPaidStatus({
    required int paymentId,
    required int year,
    required int month,
    required bool isPaid,
  }) async {
    final db = await database;
    await db.insert(
      tablePaymentStatus,
      {
        'paymentId': paymentId,
        'year': year,
        'month': month,
        'isPaid': isPaid ? 1 : 0,
        'paidDate': isPaid ? DateTime.now().toIso8601String() : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MonthlyPaymentStatus>> getMonthlyPaymentStatuses(
      int year, int month) async {
    final payments = await getActivePayments();
    final statusMap = await getPaymentStatusForMonth(year, month);

    return payments.map((payment) {
      final isPaid = statusMap[payment.id] ?? false;
      return MonthlyPaymentStatus(
        payment: payment,
        isPaid: isPaid,
        year: year,
        month: month,
      );
    }).toList()
      ..sort((a, b) => a.payment.dueDay.compareTo(b.payment.dueDay));
  }

  // ==================== LOAN CRUD ====================

  Future<int> insertLoan(Loan loan) async {
    final db = await database;
    return await db.insert(
      tableLoans,
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Loan>> getAllLoans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLoans,
      orderBy: 'endDate ASC',
    );
    return maps.map((m) => Loan.fromMap(m)).toList();
  }

  Future<List<Loan>> getActiveLoans() async {
    final db = await database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      tableLoans,
      orderBy: 'endDate ASC',
    );
    final loans = maps.map((m) => Loan.fromMap(m)).toList();
    return loans.where((l) => !l.isCompleted).toList();
  }

  Future<Loan?> getLoanById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLoans,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  Future<int> updateLoan(Loan loan) async {
    final db = await database;
    return await db.update(
      tableLoans,
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> deleteLoan(int id) async {
    final db = await database;
    return await db.delete(
      tableLoans,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementLoanPaidMonths(int id) async {
    final loan = await getLoanById(id);
    if (loan == null) return 0;
    final updated = loan.copyWith(paidMonths: loan.paidMonths + 1);
    return await updateLoan(updated);
  }

  Future<int> decrementLoanPaidMonths(int id) async {
    final loan = await getLoanById(id);
    if (loan == null) return 0;
    if (loan.paidMonths <= 0) return 0;
    final updated = loan.copyWith(paidMonths: loan.paidMonths - 1);
    return await updateLoan(updated);
  }

  // ==================== SUMMARY ====================

  Future<Map<String, double>> getMonthSummary(int year, int month) async {
    final statuses = await getMonthlyPaymentStatuses(year, month);
    double totalDue = 0;
    double totalPaid = 0;

    for (final status in statuses) {
      totalDue += status.payment.amount;
      if (status.isPaid) {
        totalPaid += status.payment.amount;
      }
    }

    final activeLoans = await getActiveLoans();
    for (final loan in activeLoans) {
      if (loan.isCurrentMonthDue) {
        totalDue += loan.monthlyAmount;
      }
    }

    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'remaining': totalDue - totalPaid,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
