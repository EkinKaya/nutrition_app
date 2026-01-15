import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _selectedFilter = 'Tümü';
  
  final List<String> _filters = [
    'Tümü',
    'Kahvaltı',
    'Öğle',
    'Akşam',
    'Atıştırmalık',
  ];

  final List<Map<String, dynamic>> _recipes = [
    {
      'title': 'Izgara Tavuk Salatası',
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      'duration': '25 dk',
      'calories': '320 kcal',
      'difficulty': 'Kolay',
      'isFavorite': false,
    },
    {
      'title': 'Kinoa & Sebze Bowl',
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      'duration': '30 dk',
      'calories': '280 kcal',
      'difficulty': 'Kolay',
      'isFavorite': true,
    },
    {
      'title': 'Somon & Avokado Toast',
      'image': 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=400',
      'duration': '15 dk',
      'calories': '380 kcal',
      'difficulty': 'Kolay',
      'isFavorite': false,
    },
    {
      'title': 'Smoothie Bowl',
      'image': 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
      'duration': '10 dk',
      'calories': '250 kcal',
      'difficulty': 'Çok Kolay',
      'isFavorite': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tarif Kitabı',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Recipes grid
          Expanded(
            child: _buildRecipesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.secondaryGradient : null,
                  color: isSelected ? null : AppColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.border.withOpacity(0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        
        return RecipeCard(
          title: recipe['title'],
          imageUrl: recipe['image'],
          duration: recipe['duration'],
          calories: recipe['calories'],
          difficulty: recipe['difficulty'],
          isFavorite: recipe['isFavorite'],
          onFavoriteToggle: () {
            setState(() {
              _recipes[index]['isFavorite'] = !recipe['isFavorite'];
            });
          },
          onTap: () {
            // Tarif detay sayfasına git
          },
        );
      },
    );
  }
}