class MatchCalculator {
  static int calculate(Map<String, dynamic> userProfile, Map<String, dynamic> restaurant) {
    if(userProfile.isEmpty) return 85;

    double score = 60.0;

    String favCuisine = (userProfile['favoriteCuisine'] ?? "").toString().toLowerCase();
    String restCuisines = (restaurant['cuisines'] ?? "").toString().toLowerCase();

    if(favCuisine.isNotEmpty && restCuisines.contains(favCuisine)) {
      score += 25;
    }

    String diet = (userProfile['dietType'] ?? "Allesesser").toString();
    String restDiets = (restaurant['dietaryRestrictions']?? "").toString();

    if(diet == "Vegetarisch" || diet == "Vegan") {
      if(restDiets.contains(diet) || restCuisines.contains(diet)) {
        score += 20;
      } else {
        score -= 40;
      }
    }

    if(score > 99) score = 99;
    if (score < 10) score = 10;

    return score.toInt();
  }

  
}