import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'restaurants.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE restaurants (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            icon TEXT,
            rating REAL,
            openingHours TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertRestaurant(Map<String, dynamic> restaurant) async {
    final db = await database;

    String openingHours = restaurant["openingHours"] is List 
      ? (restaurant["openingHours"] as List).join(" | ")
      : restaurant["openingHours"].toString();

    await db.insert('restaurants', {
      "id": restaurant["id"],
      "name": restaurant["name"],
      "description": restaurant["description"],
      "latitude": restaurant["latitude"],
      "longitude": restaurant["longitude"],
      "icon": restaurant["icon"],
      "rating": restaurant["rating"],
      "openingHours": openingHours
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final db = await database;
    return await db.query('restaurants');
  }

  Future<List<Map<String, dynamic>>> getRestaurantsInBounds(
    double minLat, double minLng, double maxLat, double maxLng
  ) async {
    final db = await database;
    return await db.query(
      'restaurants',
      where: 'latitude BETWEEN ? and ? AND longitude BETWEEN ? and ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );
  }

  Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('restaurants');
  }
}