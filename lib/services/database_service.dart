import 'dart:math';

import 'package:intl/intl.dart';
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
      version: 2,
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
            openingHours TEXT,
            priceLevel TEXT,
            cuisines TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if(oldVersion < 2) {
          await db.execute("ALTER TABLE restaurants ADD COLUMN priceLevel TEXT");
          await db.execute("ALTER TABLE restaurants ADD COLUMN cuisines TEXT");
        }
      }
    );
  }

  Future<List<Map<String, dynamic>>> getNearestRestaurantsInBounds(
    double userLat, double userLng, double minLat, double minLng, double maxLat, double maxLng, int limit
  ) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: 'latitude BETWEEN ? and ? AND longitude BETWEEN ? and ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );

    List<Map<String, dynamic>> mutableResults = results.toList();

    mutableResults.sort((a, b) {
      double distanceA = _calculateDistance(userLat, userLng, a['latitude'], a['longitude']);
      double distanceB = _calculateDistance(userLat, userLng, b['latitude'], b['longitude']);
      return distanceA.compareTo(distanceB);
    });

    return mutableResults.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> searchRestaurantsWithFilters({
    required String query,
    bool openNow = false,
    String? priceLevel,
    List<String>? cuisines,
  }) async {
    final db = await database;

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (query.isNotEmpty) {
      whereConditions.add("name LIKE ?");
      whereArgs.add('%$query%');
    }

    if (priceLevel != null && priceLevel.isNotEmpty) {
      whereConditions.add("priceLevel = ?");
      whereArgs.add(priceLevel);
    }

    String whereClause = whereConditions.isNotEmpty ? whereConditions.join(" AND ") : "";

    List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "name ASC",
    );

    if (openNow) {
      String today = DateFormat('EEEE').format(DateTime.now());
      results = results.where((restaurant) {
        if (restaurant['openingHours'] == null) return false;
        List<String> openingHoursList = restaurant['openingHours'].split(" | ");
        for (String entry in openingHoursList) {
          if (entry.startsWith(today)) {
            String hours = entry.split(': ')[1];
            if (_isWithinOpeningHours(hours)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    if (cuisines != null && cuisines.isNotEmpty) {
      results = results.where((restaurant) {
        return cuisines.any((cuisine) => (restaurant['cuisine'] ?? "").contains(cuisine));
      }).toList();
    }

    // Falls keine Treffer → Vorschläge mit "ODER"-Logik suchen
    if (results.isEmpty) {
      List<Map<String, dynamic>> alternativeResults = await db.query(
        'restaurants',
        orderBy: "rating DESC",
        limit: 10,
      );

      return alternativeResults.map((restaurant) {
        return {
          ...restaurant,
          "suggested": true, // Flag für "ODER"-Vorschläge
        };
      }).toList();
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> getOpenRestaurantsInBounds(
      double minLat, double minLng, double maxLat, double maxLng, int limit) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: 'latitude BETWEEN ? and ? AND longitude BETWEEN ? and ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );

    String today = DateFormat('EEEE').format(DateTime.now());

    results = results.where((restaurant) {
      if (restaurant['openingHours'] == null) return false;
      List<String> openingHoursList = restaurant['openingHours'].split(" | ");
      for (String entry in openingHoursList) {
        if (entry.startsWith(today)) {
          String hours = entry.split(': ')[1];
          if (_isWithinOpeningHours(hours)) {
            return true;
          }
        }
      }
      return false;
    }).toList();

    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getTopRatedRestaurants({int limit = 5}) async {
    final db = await database;
    return db.query(
      'restaurants',
      orderBy: 'rating DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getFilteredRestaurants({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    double? userLat,
    double? userLng,
    String sortBy = "rating",
    bool openNow = false,
    double minRating = 0.0,
    String? priceLevel,
    List<String>? cuisines,
    int limit = 50,
  }) async {
    final db = await database;
    /*List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: 'latitude BETWEEN ? and ? AND longitude BETWEEN ? and ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
    );*/
    List<String> whereConditions = ["latitude BETWEEN ? AND ?", 'longitude BETWEEN ? AND ?'];
    List<dynamic> whereArgs = [minLat, maxLat, minLng, maxLng];

    if (minRating > 0) {
      whereConditions.add('rating >= ?');
      whereArgs.add(minRating);
    }

    if (priceLevel != null && priceLevel.isNotEmpty) {
      whereConditions.add('priceLevel = ?');
      whereArgs.add(priceLevel);
    }

    if (cuisines != null && cuisines.isNotEmpty) {

      List<String> cuisineConditions = cuisines.map((_) => "cuisines LIKE ?").toList();

      whereConditions.add("(${cuisineConditions.join(' OR ')})");

      for (var cuisine in cuisines) {
        whereArgs.add('%$cuisine%');
      }
    }

    String whereClause = whereConditions.join(' AND ');

    List<Map<String, dynamic>> results = await db.query(
      'restaurants',
      where: whereClause,
      whereArgs: whereArgs,
    );

    List<Map<String, dynamic>> mutableResults = results.toList();

    if (openNow) {
      mutableResults = mutableResults.where((restaurant) {
        String? hoursString = restaurant["openingHours"] as String?;
        if (hoursString == null || hoursString.isEmpty) return false;
        return _isCurrentlyOpen(hoursString);
      }).toList();
    }

    if (sortBy == 'distance' && userLat != null && userLng != null) {
      mutableResults.sort((a, b) {
        double distanceA = _calculateDistance(userLat, userLng, a["latitude"], a["longitude"]);
        double distanceB = _calculateDistance(userLat, userLng, b["latitude"], b["longitude"]);
        return distanceA.compareTo(distanceB);
      });
    } else {
      mutableResults.sort((a, b) => (b["rating"] ?? 0.0).compareTo(a["rating"] ?? 0.0));
    }

    return mutableResults.take(limit).toList();

    // Filter nach Öffnungszeiten
    /*if (onlyOpenNow) {
      String today = DateFormat('EEEE').format(DateTime.now());
      results = results.where((restaurant) {
        if (restaurant['openingHours'] == null) return false;
        List<String> openingHoursList = restaurant['openingHours'].split(" | ");
        for (String entry in openingHoursList) {
          if (entry.startsWith(today)) {
            String hours = entry.split(': ')[1];
            if (_isWithinOpeningHours(hours)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }*/

    // Sortiere nach Bewertung
    /*if (sortByRating) {
      results.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    }

    // Sortiere nach Entfernung
    if (sortByDistance && userLat != null && userLng != null) {
      results.sort((a, b) {
        double distanceA = _calculateDistance(userLat, userLng, a['latitude'], a['longitude']);
        double distanceB = _calculateDistance(userLat, userLng, b['latitude'], b['longitude']);
        return distanceA.compareTo(distanceB);
      });
    }*/

    //return results.take(limit).toList();
  }

  bool _isCurrentlyOpen(String openingHoursString) {
    final now = DateTime.now();
    final todayWeekday = DateFormat('EEEE').format(now);

    List<String> hoursList = openingHoursString.split(" | ");

    for (String entry in hoursList) {
      if(entry.startsWith(todayWeekday)) {
        String hours = entry.substring(entry.indexOf(":") + 2);

        if (hours.toLowerCase() == 'closed') return false;
        if (hours.toLowerCase() == 'open 24 hours') return true;

        try {
          final parts = hours.split(" - ");
          if (parts.length != 2) continue;

          final startTime = _parseTime(parts[0]);
          final endTime = _parseTime(parts[1]);

          final nowTime = now.hour * 60 + now.minute;

          if(endTime < startTime) {
            if (nowTime >= startTime || nowTime < endTime) {
              return true;
            }
          } else {
            if (nowTime >= startTime && nowTime < endTime) {
              return true;
            }
          }
        } catch (e) {
          print("Fehler beim Parsen der Öffnungszeit: '$hours' - $e");
          continue;
        }
      }
    }

    return false;
  }

  int _parseTime(String time) {
    final format = DateFormat("h:mm a");
    final dt = format.parse(time);
    return dt.hour * 60 + dt.minute;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Erdradius in km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) + cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  bool _isWithinOpeningHours(String openingHours) {
    if (openingHours.toLowerCase().contains("open 24 hours")) {
      return true; // Immer geöffnet
    }
    if (openingHours.toLowerCase().contains("closed")) {
      return false; // Geschlossen
    }

    final now = DateTime.now();
    String currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Öffnungszeiten ins 24-Stunden-Format umwandeln
    String convertedTime = _convertTo24HourFormat(openingHours);

    List<String> parts = convertedTime.split(" - ");
    
    if (parts.length != 2) {
      print("⚠️ Ungültige Öffnungszeiten: $openingHours -> $convertedTime");
      return false;
    }

    return currentTime.compareTo(parts[0]) >= 0 && currentTime.compareTo(parts[1]) <= 0;
  }

  String _convertTo24HourFormat(String timeRange) {
    return timeRange.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)\s?[–-]\s?(\d{1,2}):(\d{2})\s?(AM|PM)'),
      (Match m) {
        int startHour = int.parse(m[1]!);
        String startMinute = m[2]!;
        String startPeriod = m[3]!;

        int endHour = int.parse(m[4]!);
        String endMinute = m[5]!;
        String endPeriod = m[6]!;

        // Startzeit umwandeln
        if (startPeriod == "PM" && startHour != 12) {
          startHour += 12;
        } else if (startPeriod == "AM" && startHour == 12) {
          startHour = 0;
        }

        // Endzeit umwandeln
        if (endPeriod == "PM" && endHour != 12) {
          endHour += 12;
        } else if (endPeriod == "AM" && endHour == 12) {
          endHour = 0;
        }

        return "${startHour.toString().padLeft(2, '0')}:$startMinute - ${endHour.toString().padLeft(2, '0')}:$endMinute";
      },
    );
  }


  Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    final db = await database;
    return await db.query(
      'restaurants',
      where: "name LIKE ?",
      whereArgs: ['%$query%'],
      orderBy: "name ASC",
    );
  }

  Future<void> insertRestaurant(Map<String, dynamic> restaurant) async {
    final db = await database;

    String openingHours = restaurant["openingHours"] is List 
      ? (restaurant["openingHours"] as List).join(" | ")
      : restaurant["openingHours"].toString();

    String cuisines = restaurant["cuisines"] is List
      ? (restaurant["cuisines"] as List).join(", ")
      : restaurant["cuisines"]?.toString() ?? "";

    await db.insert('restaurants', {
      "id": restaurant["id"],
      "name": restaurant["name"],
      "description": restaurant["description"],
      "latitude": restaurant["latitude"],
      "longitude": restaurant["longitude"],
      "icon": restaurant["icon"],
      "rating": restaurant["rating"],
      "openingHours": openingHours,
      "priceLevel": restaurant["priceLevel"],
      "cuisines": cuisines
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

  Future<List<Map<String, dynamic>>> getHighestRatedInBounds(
    double minLat, double minLng, double maxLat, double maxLng, int limit
  ) async {
    final db = await database;
    return await db.query(
      'restaurants',
      where: 'latitude BETWEEN ? and ? AND longitude BETWEEN ? and ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
      orderBy: 'rating DESC',
      limit: limit,
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

  Future<void> setRestaurantRating(String restaurantId, double rating) async {
    final db = await database;
    await db.update(
      'restaurants',
      {'rating': rating},
      where: 'id = ?',
      whereArgs: [restaurantId],
    );
  }
  
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('restaurants');
  }
}