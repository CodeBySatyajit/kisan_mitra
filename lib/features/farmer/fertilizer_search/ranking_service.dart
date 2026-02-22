import 'fertilizer_search_model.dart';

class RankingService {
  // Weights
  // Weights
  static const double ratingWeight = 0.4;
  static const double reviewWeight = 0.2;
  static const double priceWeight = 0.3;
  static const double distanceWeight = 0.1;

  List<StoreSearchResult> rankStores(List<StoreSearchResult> results) {
    if (results.isEmpty) return [];

    // 1. Calculate Global maximums/minimums for normalization
    double minPrice = double.infinity;
    int maxReviews = 0;

    for (var result in results) {
      final price = result.price;
      if (price != null && price < minPrice && price > 0) {
        minPrice = price;
      }
      if (result.store.totalReviews > maxReviews) {
        maxReviews = result.store.totalReviews;
      }
    }

    if (minPrice == double.infinity) minPrice = 0;

    List<StoreSearchResult> rankedResults = [];

    for (var result in results) {
      // 1. Normalized Rating (0 to 1)
      double normalizedRating = result.store.rating / 5.0;

      // 2. Normalized Review Score (0 to 1)
      double normalizedReviewScore = 0.0;
      if (maxReviews > 0) {
        normalizedReviewScore = result.store.totalReviews / maxReviews;
      }

      // 3. Price Score (0 to 1) - Lower is better
      double priceScore = 0.0;
      final price = result.price;
      if (price != null && price > 0) {
        priceScore = minPrice / price;
      }

      // 4. Distance Score (0 to 1) - Closer is better
      // score = 1 - (distance / 5)
      // Assuming max radius is 5km. If distance > 5, score becomes negative, clamp to 0.
      double distanceScore = 1.0 - (result.distance / 5.0);
      if (distanceScore < 0) distanceScore = 0.0;

      // Final Score Calculation
      double score =
          (ratingWeight * normalizedRating) +
          (reviewWeight * normalizedReviewScore) +
          (priceWeight * priceScore) +
          (distanceWeight * distanceScore);

      rankedResults.add(
        StoreSearchResult(
          store: result.store,
          distance: result.distance,
          score: score,
          price: result.price,
          inStock: result.inStock,
        ),
      );
    }

    // Sort descending by score
    rankedResults.sort((a, b) => b.score.compareTo(a.score));

    return rankedResults;
  }
}
