import 'dart:math';

class MatchCalculator {
  static int calculate(
      Map<String, dynamic>? userProfile, Map<String, dynamic> restaurant) {
    double score = 40.0; // Base score

    // Rating (0 to 5) -> scale to max 25 points
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;
    score += rating * 5;

    // OpenNow
    final isOpen = restaurant['isOpenNow'] as bool? ?? false;
    if (isOpen) {
      score += 10;
    }

    // Price Match
    final price = (restaurant['priceLevel'] ?? "").toString();
    if (userProfile != null && userProfile['priceRange'] != null) {
      final userPrice = userProfile['priceRange'].toString();
      if (price == userPrice) {
        score += 15; // exact match
      } else if ((price == '€' && userPrice == '€€') ||
          (price == '€€' && userPrice == '€')) {
        score += 8; // close match
      } else if (price == '€€€€' || price == 'Expensive') {
        score -= 5;
      }
    } else {
      // Fallback: favor cheap/moderate
      if (price == "€" || price == "Inexpensive") {
        score += 10;
      } else if (price == "€€" || price == "Moderate") {
        score += 5;
      } else if (price == "€€€" || price == "Expensive") {
        score -= 5;
      }
    }

    // Distance
    if (userProfile != null &&
        userProfile['latitude'] != null &&
        userProfile['longitude'] != null) {
      final userLat = (userProfile['latitude'] as num).toDouble();
      final userLng = (userProfile['longitude'] as num).toDouble();
      final restLat = (restaurant['latitude'] as num?)?.toDouble() ?? 0.0;
      final restLng = (restaurant['longitude'] as num?)?.toDouble() ?? 0.0;

      if (restLat != 0.0 && restLng != 0.0) {
        final distanceKm =
            _calculateDistance(userLat, userLng, restLat, restLng);

        if (distanceKm < 1.0) {
          score += 20;
        } else if (distanceKm < 3.0) {
          score += 15;
        } else if (distanceKm < 10.0) {
          score += 5;
        } else {
          score -= 10;
        }
      }
    }

    // ─── Cuisine Preferences (multi-select) ───
    if (userProfile != null) {
      final favCuisines = userProfile['favoriteCuisines'];
      String restCuisines =
          (restaurant['cuisines'] ?? "").toString().toLowerCase();

      if (favCuisines is List && favCuisines.isNotEmpty) {
        bool anyMatch = false;
        for (final c in favCuisines) {
          if (restCuisines.contains(c.toString().toLowerCase())) {
            anyMatch = true;
            break;
          }
        }
        if (anyMatch) {
          score += 15;
        }
      } else {
        // Fallback: single favoriteCuisine (legacy)
        String favCuisine =
            (userProfile['favoriteCuisine'] ?? "").toString().toLowerCase();
        if (favCuisine.isNotEmpty && restCuisines.contains(favCuisine)) {
          score += 10;
        }
      }

      // Diet
      String diet = (userProfile['dietType'] ?? "Allesesser").toString();
      String restDiets = (restaurant['dietaryRestrictions'] ?? "").toString();

      if (diet == "Vegetarisch" || diet == "Vegan") {
        if (restDiets.contains(diet) ||
            restCuisines.contains(diet.toLowerCase())) {
          score += 10;
        } else {
          score -= 20;
        }
      }
    }

    return score.clamp(10.0, 99.0).toInt();
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
