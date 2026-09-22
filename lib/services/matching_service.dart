import '../models/asset.dart';
import '../models/found_item.dart';

class MatchScore {
  final double score; // 0.0 to 100.0
  final bool isStrongMatch;
  final List<String> matchingFactors;
  final Asset matchedAsset;

  const MatchScore({
    required this.score,
    required this.isStrongMatch,
    required this.matchingFactors,
    required this.matchedAsset,
  });

  int get percentage => score.round().clamp(0, 100);
}

class MatchingService {
  /// Compares a [FoundItem] against a list of registered/lost [Asset]s
  /// and returns matches sorted by score descending.
  static List<MatchScore> findPossibleMatches(
    FoundItem foundItem,
    List<Asset> candidates, {
    double threshold = 40.0,
  }) {
    final List<MatchScore> results = [];

    for (final asset in candidates) {
      // Don't match against already recovered items unless needed
      if (asset.status == AssetStatus.recovered) continue;

      final match = evaluateMatch(foundItem: foundItem, asset: asset);
      if (match.score >= threshold || match.isStrongMatch) {
        results.add(match);
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Evaluates matching confidence between a [FoundItem] and an [Asset].
  static MatchScore evaluateMatch({
    required FoundItem foundItem,
    required Asset asset,
  }) {
    double score = 0.0;
    final List<String> factors = [];
    // 1. Serial Number check (Critical match: unique identifier)
    final foundSerial = _normalize(foundItem.serialNumber);
    final assetSerial = _normalize(asset.serialNumber);
    if (foundSerial.isNotEmpty && assetSerial.isNotEmpty) {
      if (foundSerial == assetSerial) {
        factors.add('Exact Serial Number Match ($assetSerial)');
        return MatchScore(
          score: 100.0,
          isStrongMatch: true,
          matchingFactors: factors,
          matchedAsset: asset,
        );
      }
    }

    // 2. Registration Number check (Critical for vehicles, bicycles, etc.)
    final foundReg = _normalize(foundItem.registrationNumber);
    final assetReg = _normalize(asset.registrationNumber);
    if (foundReg.isNotEmpty && assetReg.isNotEmpty) {
      if (foundReg == assetReg) {
        factors.add('Exact Registration Match ($assetReg)');
        return MatchScore(
          score: 100.0,
          isStrongMatch: true,
          matchingFactors: factors,
          matchedAsset: asset,
        );
      }
    }

    // 3. Category match
    final foundCat = foundItem.category.trim().toLowerCase();
    final assetCat = asset.categoryName.trim().toLowerCase();
    if (foundCat == assetCat) {
      score += 25.0;
      factors.add('Category Match (${asset.categoryName})');
    } else if (foundCat.isNotEmpty && assetCat.isNotEmpty) {
      // If categories are completely different (e.g. phone vs car), penalize
      if ((foundCat == 'car' || foundCat == 'bike') && (assetCat != 'car' && assetCat != 'bike')) {
        return MatchScore(
          score: 0.0,
          isStrongMatch: false,
          matchingFactors: const [],
          matchedAsset: asset,
        );
      }
    }

    // 4. Brand & Model match
    final foundBrand = _normalize(foundItem.brand);
    final assetBrand = _normalize(asset.brand);
    if (foundBrand.isNotEmpty && assetBrand.isNotEmpty) {
      if (foundBrand == assetBrand ||
          foundBrand.contains(assetBrand) ||
          assetBrand.contains(foundBrand)) {
        score += 25.0;
        factors.add('Brand Match (${asset.brand})');
      }
    }

    final foundModel = _normalize(foundItem.model);
    final assetModel = _normalize(asset.model);
    if (foundModel.isNotEmpty && assetModel.isNotEmpty) {
      if (foundModel == assetModel ||
          foundModel.contains(assetModel) ||
          assetModel.contains(foundModel)) {
        score += 20.0;
        factors.add('Model Match (${asset.model})');
      }
    }

    // 5. Color match
    final foundColor = _normalize(foundItem.color);
    final assetColor = _normalize(asset.color);
    if (foundColor.isNotEmpty && assetColor.isNotEmpty) {
      if (foundColor == assetColor ||
          foundColor.contains(assetColor) ||
          assetColor.contains(foundColor)) {
        score += 15.0;
        factors.add('Color Match (${asset.color})');
      }
    }

    // 6. Name / Description token overlap
    final foundTokens = _tokenize('${foundItem.itemName} ${foundItem.description ?? ''}');
    final assetTokens = _tokenize('${asset.name} ${asset.model} ${asset.brand}');
    final commonTokens = foundTokens.intersection(assetTokens);
    if (commonTokens.isNotEmpty) {
      score += (commonTokens.length * 5.0).clamp(0.0, 15.0);
      factors.add('Keyword Overlap (${commonTokens.take(3).join(', ')})');
    }

    // 7. Status boost: if asset is currently marked as LOST, increase priority
    if (asset.isLost) {
      score += 10.0;
      factors.add('Reported Lost by Owner');
    }

    return MatchScore(
      score: score.clamp(0.0, 100.0),
      isStrongMatch: score >= 75.0,
      matchingFactors: factors,
      matchedAsset: asset,
    );
  }

  static String _normalize(String? input) {
    if (input == null) return '';
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static Set<String> _tokenize(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return clean
        .split(RegExp(r'\s+'))
        .where((s) => s.length >= 3)
        .where((s) => !_stopWords.contains(s))
        .toSet();
  }

  static const _stopWords = {
    'the', 'and', 'for', 'with', 'from', 'this', 'that', 'item', 'lost', 'found',
  };
}
