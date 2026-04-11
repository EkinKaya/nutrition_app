import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/recipe_service.dart';
import '../../calendar/widgets/portion_dialog.dart';

// ---------------------------------------------------------------------------
// Simple recipe content parser
// ---------------------------------------------------------------------------
class _ParsedRecipe {
  final int? caloriesMin;
  final int? caloriesMax;
  final List<String> ingredients;
  final List<String> steps;

  const _ParsedRecipe({
    this.caloriesMin,
    this.caloriesMax,
    required this.ingredients,
    required this.steps,
  });
}

_ParsedRecipe _parseRecipe(String content) {
  final lines = content.split('\n').map((l) => l.trim()).toList();

  // --- Calories ---
  int? calMin, calMax;
  final calRegex = RegExp(
    r'(\d{2,4})\s*[-–]\s*(\d{2,4})\s*(kcal|kalori)|'
    r'~?\s*(\d{2,4})\s*(kcal|kalori)',
    caseSensitive: false,
  );
  for (final line in lines) {
    final m = calRegex.firstMatch(line);
    if (m != null) {
      if (m.group(1) != null && m.group(2) != null) {
        calMin = int.tryParse(m.group(1)!);
        calMax = int.tryParse(m.group(2)!);
      } else if (m.group(4) != null) {
        final v = int.tryParse(m.group(4)!);
        calMin = v != null ? (v * 0.9).round() : null;
        calMax = v != null ? (v * 1.1).round() : null;
      }
      break;
    }
  }

  // --- Section detection ---
  final ingredientKeywords = RegExp(
    r'malzeme|içindekiler|ingredient',
    caseSensitive: false,
  );
  final stepKeywords = RegExp(
    r'hazırlık|yapılış|adımlar|yapım|tarif|talimat|preparation|steps|directions',
    caseSensitive: false,
  );

  final List<String> ingredients = [];
  final List<String> steps = [];

  String section = '';
  for (int i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final clean = raw.replaceAll('**', '').replaceAll('*', '').replaceAll('#', '').trim();
    if (clean.isEmpty) continue;

    if (ingredientKeywords.hasMatch(clean)) {
      section = 'ingredients';
      continue;
    }
    if (stepKeywords.hasMatch(clean)) {
      section = 'steps';
      continue;
    }

    if (section == 'ingredients') {
      // Stop if we hit another section header
      if (stepKeywords.hasMatch(clean)) {
        section = 'steps';
        continue;
      }
      final item = clean
          .replaceFirst(RegExp(r'^[-•*]\s*'), '')
          .replaceFirst(RegExp(r'^\d+[.)]\s*'), '')
          .trim();
      if (item.isNotEmpty && item.length > 1) {
        ingredients.add(item);
      }
    } else if (section == 'steps') {
      // Stop if we hit another section header
      if (ingredientKeywords.hasMatch(clean)) {
        section = 'ingredients';
        continue;
      }
      final item = clean
          .replaceFirst(RegExp(r'^[-•*]\s*'), '')
          .replaceFirst(RegExp(r'^\d+[.)]\s*'), '')
          .trim();
      if (item.isNotEmpty && item.length > 2) {
        steps.add(item);
      }
    }
  }

  // Fallback: if no sections found, treat numbered lines as steps
  if (steps.isEmpty && ingredients.isEmpty) {
    for (final line in lines) {
      final clean = line
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('#', '')
          .trim();
      if (RegExp(r'^\d+[.)]\s+').hasMatch(clean)) {
        steps.add(clean.replaceFirst(RegExp(r'^\d+[.)]\s+'), '').trim());
      } else if (clean.startsWith('- ') || clean.startsWith('• ')) {
        ingredients.add(clean.substring(2).trim());
      }
    }
  }

  return _ParsedRecipe(
    caloriesMin: calMin,
    caloriesMax: calMax,
    ingredients: ingredients,
    steps: steps,
  );
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late Stream<List<Recipe>> _recipesStream;

  @override
  void initState() {
    super.initState();
    _recipesStream = RecipeService.getRecipesStream();
  }

  void _refreshStream() {
    setState(() {
      _recipesStream = RecipeService.getRecipesStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: StreamBuilder<List<Recipe>>(
          stream: _recipesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final recipes = snapshot.data ?? [];

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tarif Kitabı',
                              style: GoogleFonts.urbanist(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${recipes.length} tarif kayıtlı',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: recipes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            return _RecipeListCard(
                              recipe: recipes[index],
                              onDelete: () => _showDeleteDialog(recipes[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Tarif kitabın boş',
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'AI sohbetinde oluşturulan tariflere\nbasılı tutarak kitabına ekleyebilirsin',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.4),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.7), size: 48),
          const SizedBox(height: 16),
          Text(
            'Tarifler yüklenemedi',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshStream,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Tekrar Dene',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tarifi Sil',
          style: GoogleFonts.urbanist(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${recipe.title}" tarifini silmek istediğine emin misin?',
          style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RecipeService.deleteRecipe(recipe.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tarif silindi', style: GoogleFonts.inter()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                Text('Sil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List card (profile-style row)
// ---------------------------------------------------------------------------
class _RecipeListCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onDelete;

  const _RecipeListCard({
    required this.recipe,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailOverlay(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(recipe.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.25),
                  size: 20,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white.withOpacity(0.35),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return _RecipeDetailDialog(recipe: recipe);
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Detail overlay with flip animation
// ---------------------------------------------------------------------------
class _RecipeDetailDialog extends StatefulWidget {
  final Recipe recipe;

  const _RecipeDetailDialog({required this.recipe});

  @override
  State<_RecipeDetailDialog> createState() => _RecipeDetailDialogState();
}

class _RecipeDetailDialogState extends State<_RecipeDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _showingBack = false;

  late _ParsedRecipe _parsed;

  @override
  void initState() {
    super.initState();
    _parsed = _parseRecipe(widget.recipe.content);
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    _flipAnim.addListener(() {
      final shouldShowBack = _flipAnim.value > pi / 2;
      if (shouldShowBack != _showingBack) {
        setState(() => _showingBack = shouldShowBack);
      }
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    if (_showingBack) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: screenW,
            height: screenH * 0.72,
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(_flipAnim.value),
                  alignment: Alignment.center,
                  child: _showingBack ? _buildBack() : _buildFront(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.title,
                        style: GoogleFonts.urbanist(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(widget.recipe.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Content preview (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              physics: const BouncingScrollPhysics(),
              child: Text(
                widget.recipe.content,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.75,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),

          // Detay button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _flip,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Detay',
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    // Back face is mirrored (rendered after 180° rotation)
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Back header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _flip,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.recipe.title,
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Parsed detail content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calories
                    if (_parsed.caloriesMin != null)
                      _buildSection(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.orange,
                        title: 'Porsiyon Kalori',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _parsed.caloriesMax != null
                                    ? '${_parsed.caloriesMin} – ${_parsed.caloriesMax} kcal'
                                    : '~${_parsed.caloriesMin} kcal',
                                style: GoogleFonts.urbanist(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_parsed.caloriesMin != null) const SizedBox(height: 20),

                    // Ingredients
                    if (_parsed.ingredients.isNotEmpty)
                      _buildSection(
                        icon: Icons.shopping_basket_rounded,
                        iconColor: AppColors.primary,
                        title: 'Malzemeler',
                        child: Column(
                          children: _parsed.ingredients
                              .map((ing) => _buildBulletItem(ing, AppColors.primary))
                              .toList(),
                        ),
                      ),

                    if (_parsed.ingredients.isNotEmpty) const SizedBox(height: 20),

                    // Steps
                    if (_parsed.steps.isNotEmpty)
                      _buildSection(
                        icon: Icons.format_list_numbered_rounded,
                        iconColor: const Color(0xFF7B9CFF),
                        title: 'Hazırlık Adımları',
                        child: Column(
                          children: _parsed.steps
                              .asMap()
                              .entries
                              .map((e) => _buildStepItem(e.key + 1, e.value))
                              .toList(),
                        ),
                      ),

                    // Fallback: no structured data
                    if (_parsed.ingredients.isEmpty &&
                        _parsed.steps.isEmpty &&
                        _parsed.caloriesMin == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Yapılandırılmış detay bulunamadı.\nÖn yüzden tarife bakabilirsin.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.4),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Takvime Ekle button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => PortionDialog(
                        mealName: widget.recipe.title,
                        foodDescription: widget.recipe.content,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B9CFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    'Takvime Ekle',
                    style: GoogleFonts.urbanist(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 17),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildBulletItem(String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.55,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9CFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B9CFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.55,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
