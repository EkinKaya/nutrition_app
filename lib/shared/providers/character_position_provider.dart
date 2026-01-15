import 'package:flutter/material.dart';
import '../widgets/fruit_character.dart';

class CharacterPositionProvider extends ChangeNotifier {
  // Her sayfa için karakter pozisyonları - KAPATILDI, her sayfa kendi karakterini gösterecek
  static const Map<int, CharacterPageConfig> _pageConfigs = {
    0: CharacterPageConfig(
      position: Alignment(-0.85, -0.85),  // HomeScreen - tamamen gizli
      size: FruitSize.small,
      showPlatform: false,
    ),
    1: CharacterPageConfig(
      position: Alignment(0.7, -0.85),   // ActivityScreen - tamamen gizli
      size: FruitSize.medium,
      showPlatform: false,
    ),
    2: CharacterPageConfig(
      position: Alignment(0.0, -0.85),  // RecipesScreen - tamamen gizli
      size: FruitSize.small,
      showPlatform: false,
    ),
    3: CharacterPageConfig(
      position: Alignment(0.0, -0.85),  // ProfileScreen - tamamen gizli
      size: FruitSize.large,
      showPlatform: false,
    ),
  };

  int _currentPage = 0;
  int _previousPage = 0;
  bool _isTransitioning = false;

  int get currentPage => _currentPage;
  int get previousPage => _previousPage;
  bool get isTransitioning => _isTransitioning;

  CharacterPageConfig get currentConfig => _pageConfigs[_currentPage]!;
  CharacterPageConfig get previousConfig => _pageConfigs[_previousPage]!;

  void navigateToPage(int newPage) {
    if (_currentPage == newPage || _isTransitioning) return;

    _previousPage = _currentPage;
    _currentPage = newPage;
    _isTransitioning = true;
    notifyListeners();
  }

  void completeTransition() {
    _isTransitioning = false;
    notifyListeners();
  }

  CharacterPageConfig getConfigForPage(int page) {
    return _pageConfigs[page] ?? _pageConfigs[0]!;
  }
}

class CharacterPageConfig {
  final Alignment position;
  final FruitSize size;
  final bool showPlatform;

  const CharacterPageConfig({
    required this.position,
    required this.size,
    required this.showPlatform,
  });
}
