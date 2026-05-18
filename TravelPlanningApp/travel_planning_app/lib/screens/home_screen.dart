import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_package_model.dart';
import '../services/api_service.dart';
import 'destination_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final VoidCallback? onOpenAiPlanner;

  const HomeScreen({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.onOpenAiPlanner,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AiPackageModel> aiPackages = [];
  List<AiPackageSuggestion> packageSuggestions = [];
  bool isLoadingPackages = false;
  bool isLoadingSuggestions = false;
  String? packagesError;
  String? selectedInterest;
  Timer? _searchDebounce;

  static const _luxuryBackground = Color(0xFF030303);
  static const _luxuryCard = Color(0xFF0B1020);
  static const _luxuryGold = Color(0xFFE8C766);
  static const _luxurySecondaryText = Color(0xFFB8B8B8);
  static const _nightBackground = Color(0xFF050818);
  static const _nightCard = Color(0xFF111827);
  static const _nightPurple = Color(0xFFA855F7);
  static const _nightPink = Color(0xFFEC4899);
  static const _nightSecondaryText = Color(0xFFB8B8D1);

  @override
  void initState() {
    super.initState();
    _loadAiPackages();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMode != widget.selectedMode) {
      selectedInterest = null;
      packageSuggestions = [];
      _loadAiPackages();
      _loadSuggestions();
    }
  }

  Future<void> _loadAiPackages() async {
    final query = _searchController.text.trim();
    final interests = selectedInterest == null ? null : [selectedInterest!];

    setState(() {
      isLoadingPackages = true;
      packagesError = null;
    });

    try {
      final packages = await _apiService.getAiPackages(
        mode: widget.selectedMode,
        query: query.isEmpty ? null : query,
        interests: interests,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        aiPackages = packages;
        isLoadingPackages = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        aiPackages = [];
        packagesError = error.toString();
        isLoadingPackages = false;
      });
    }
  }

  void _queueSearch(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadAiPackages();
      _loadSuggestions();
    });
  }

  Future<void> _loadSuggestions() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      if (!mounted) return;

      setState(() {
        packageSuggestions = [];
        isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final suggestions = await _apiService.getAiPackageSuggestions(
        mode: widget.selectedMode,
        query: query,
        interests: selectedInterest == null ? null : [selectedInterest!],
        limit: 5,
      );

      if (!mounted) return;

      setState(() {
        packageSuggestions = suggestions;
        isLoadingSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        packageSuggestions = [];
        isLoadingSuggestions = false;
      });
    }
  }

  void _selectSuggestion(AiPackageSuggestion suggestion) {
    _searchDebounce?.cancel();
    _searchController.text = suggestion.value;
    setState(() {
      packageSuggestions = [];
    });
    _loadAiPackages();
  }

  void _toggleInterest(String interest) {
    setState(() {
      selectedInterest = selectedInterest == interest ? null : interest;
      packageSuggestions = [];
    });
    _loadAiPackages();
    _loadSuggestions();
  }

  List<String> _interestOptions() {
    if (widget.selectedMode == 'Luxury') {
      return ['Private', 'Fine dining', 'Scenic flights', 'Exclusive stays'];
    }
    if (widget.selectedMode == 'Night') {
      return ['Clubs', 'Bars', 'Rooftops', 'Live music'];
    }
    return ['Nature', 'Adventure', 'Culture', 'Beach'];
  }

  IconData _interestIcon(String interest) {
    switch (interest) {
      case 'Private':
        return Icons.lock_outline;
      case 'Fine dining':
        return Icons.restaurant_menu;
      case 'Scenic flights':
        return Icons.flight_takeoff;
      case 'Exclusive stays':
        return Icons.villa_outlined;
      case 'Clubs':
        return Icons.nightlife;
      case 'Bars':
        return Icons.local_bar;
      case 'Rooftops':
        return Icons.apartment;
      case 'Live music':
        return Icons.music_note;
      case 'Nature':
        return Icons.park;
      case 'Adventure':
        return Icons.hiking;
      case 'Culture':
        return Icons.account_balance;
      case 'Beach':
        return Icons.beach_access;
      default:
        return Icons.label_outline;
    }
  }

  String _packageSubtitle(AiPackageModel package) {
    final location = [
      package.city,
      package.country,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    if (location.isNotEmpty) {
      return location;
    }

    return package.subtitle;
  }

  String _packageTag(AiPackageModel package) {
    if (selectedInterest != null) {
      return selectedInterest!;
    }
    if (package.tag.trim().isNotEmpty) {
      return package.tag;
    }
    return widget.selectedMode;
  }

  void _openPackage(AiPackageModel package) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationDetailsScreen(
          destination: package.title,
          country: package.country,
          selectedMode: widget.selectedMode,
          package: package,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';
    final options = _interestOptions();
    final accentColor = isLuxury
        ? _luxuryGold
        : isNight
            ? _nightPurple
            : const Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      backgroundColor: isLuxury || isNight ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.selectedMode} package filters',
                  style: TextStyle(
                    color: isLuxury || isNight ? Colors.white : const Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((option) {
                    final selected = selectedInterest == option;
                    return ChoiceChip(
                      label: Text(option),
                      avatar: Icon(
                        _interestIcon(option),
                        size: 16,
                        color: selected
                            ? Colors.white
                            : isLuxury || isNight
                                ? accentColor
                                : const Color(0xFF2563EB),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        Navigator.pop(context);
                        _toggleInterest(option);
                      },
                      selectedColor: accentColor,
                      backgroundColor: isLuxury || isNight
                          ? const Color(0xFF0B1020)
                          : const Color(0xFFEFF6FF),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : isLuxury || isNight
                                ? Colors.white
                                : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
                if (selectedInterest != null) ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleInterest(selectedInterest!);
                    },
                    child: Text(
                      'Clear filter',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';
    final backgroundColor = isLuxury
        ? _luxuryBackground
        : isNight
            ? _nightBackground
            : const Color(0xFFFDFDFD);
    final primaryTextColor = isLuxury
        ? const Color(0xFFFFF8E1)
        : isNight
            ? Colors.white
            : const Color(0xFF111827);
    final accentColor = isLuxury
        ? _luxuryGold
        : isNight
            ? _nightPurple
            : const Color(0xFF2563EB);
    final secondaryTextColor = isLuxury
        ? _luxurySecondaryText
        : isNight
            ? _nightSecondaryText
            : const Color(0xFF6B7280);
    final shadowColor =
        isLuxury || isNight ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLuxury
                    ? 'Plan your premium escape'
                    : isNight
                        ? 'Plan your next night out'
                        : 'Plan your trip',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),

              if (isLuxury || isNight) ...[
                const SizedBox(height: 6),
                Text(
                  isLuxury
                      ? 'Private tours, scenic flights & exclusive experiences'
                      : 'Clubs, bars & late-night hotspots',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Column(
                children: [
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isLuxury
                          ? _luxuryCard
                          : isNight
                              ? _nightCard
                              : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLuxury
                            ? _luxuryGold.withOpacity(0.35)
                            : isNight
                                ? _nightPurple.withOpacity(0.35)
                                : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _queueSearch,
                            onSubmitted: (_) {
                              _searchDebounce?.cancel();
                              setState(() {
                                packageSuggestions = [];
                              });
                              _loadAiPackages();
                            },
                            style: TextStyle(
                              color: isLuxury || isNight
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: accentColor,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: isLuxury
                                  ? 'Search private tours, villas, or premium stays...'
                                  : isNight
                                      ? 'Search clubs, bars, or cities...'
                                      : 'Search cities, packages, or interests...',
                              hintStyle: TextStyle(
                                color: isLuxury || isNight
                                    ? secondaryTextColor
                                    : const Color(0xFFB0B7C3),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() {
                                packageSuggestions = [];
                              });
                              _loadAiPackages();
                            },
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: isLuxury || isNight
                                  ? secondaryTextColor
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Filter packages',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            Icons.tune,
                            color: isLuxury || isNight
                                ? accentColor
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (packageSuggestions.isNotEmpty || isLoadingSuggestions)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isLuxury || isNight
                            ? const Color(0xFF111827)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLuxury
                              ? _luxuryGold.withOpacity(0.35)
                              : isNight
                                  ? _nightPurple.withOpacity(0.35)
                                  : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: isLoadingSuggestions
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Column(
                              children: packageSuggestions.map((suggestion) {
                                final location = [
                                  suggestion.city,
                                  suggestion.country,
                                ]
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(', ');

                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.travel_explore,
                                    color: accentColor,
                                  ),
                                  title: Text(
                                    suggestion.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isLuxury || isNight
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: location.isEmpty
                                      ? null
                                      : Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              }).toList(),
                            ),
                    ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  _ModeButton(
                    text: 'Casual',
                    icon: Icons.wb_sunny_outlined,
                    isSelected: widget.selectedMode == 'Casual',
                    selectedMode: widget.selectedMode,
                    onTap: () => widget.onModeChanged('Casual'),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    text: 'Luxury',
                    icon: Icons.diamond_outlined,
                    isSelected: widget.selectedMode == 'Luxury',
                    selectedMode: widget.selectedMode,
                    onTap: () => widget.onModeChanged('Luxury'),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    text: 'Night',
                    icon: Icons.nightlight_round,
                    isSelected: widget.selectedMode == 'Night',
                    selectedMode: widget.selectedMode,
                    onTap: () => widget.onModeChanged('Night'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLuxury
                        ? _luxuryGold.withOpacity(0.45)
                        : isNight
                            ? _nightPurple.withOpacity(0.45)
                            : Colors.transparent,
                  ),
                  gradient: LinearGradient(
                    colors: isLuxury
                        ? const [
                            Color(0xFF0B1020),
                            Color(0xFF111827),
                          ]
                        : isNight
                            ? const [
                                Color(0xFF111827),
                                Color(0xFF2E1065),
                              ]
                            : const [
                                Color(0xFF2563EB),
                                Color(0xFF60A5FA),
                              ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI POWERED',
                            style: TextStyle(
                              color: isLuxury || isNight ? accentColor : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLuxury
                                ? 'Let AI build your\nperfect luxury escape'
                                : isNight
                                    ? 'Perfect\nnight'
                                    : 'Let AI build your\nperfect trip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLuxury
                                ? 'Private stays, premium transfers, and exclusive moments in one plan.'
                                : isNight
                                    ? 'Tell us your vibe and we will craft the ideal nightlife experience for you.'
                                    : 'Tell us your vibe and we will craft the ideal trip for you.',
                            style: TextStyle(
                              color: isLuxury || isNight ? secondaryTextColor : Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: widget.onOpenAiPlanner,
                              icon: Icon(
                                isLuxury
                                    ? Icons.diamond_outlined
                                    : isNight
                                        ? Icons.nightlife
                                        : Icons.add,
                                size: 18,
                              ),
                              label: Text(
                                isLuxury
                                    ? 'Create AI Luxury Plan'
                                    : isNight
                                        ? 'Create AI Night Plan'
                                        : 'Create AI Package',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isLuxury
                                    ? _luxuryCard
                                    : isNight
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                backgroundColor: isLuxury
                                    ? _luxuryGold
                                    : isNight
                                        ? _nightPink
                                        : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLuxury
                          ? Icons.auto_awesome
                          : isNight
                              ? Icons.nightlife
                              : Icons.smart_toy_outlined,
                      color: isLuxury || isNight ? accentColor : Colors.white,
                      size: 78,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _interestOptions().map((interest) {
                    return _InterestChip(
                      text: interest,
                      icon: _interestIcon(interest),
                      isSelected: selectedInterest == interest,
                      isLuxury: isLuxury,
                      isNight: isNight,
                      onTap: () => _toggleInterest(interest),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 26),

              _SectionHeader(
                title: 'Suggested for you',
                actionText: 'See all',
                isLuxury: isLuxury,
                isNight: isNight,
              ),

              const SizedBox(height: 14),

              if (isLoadingPackages && aiPackages.isEmpty)
                const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (packagesError != null && aiPackages.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Could not load packages.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else if (aiPackages.isNotEmpty)
                _SuggestedPackageCard(
                  package: aiPackages.first,
                  tag: _packageTag(aiPackages.first),
                  isLuxury: isLuxury,
                  isNight: isNight,
                  onTap: () => _openPackage(aiPackages.first),
                )
              else
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No ${widget.selectedMode.toLowerCase()} packages found.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 26),

              _SectionHeader(
                title: 'Ready-made packages',
                actionText: 'See all',
                isLuxury: isLuxury,
                isNight: isNight,
              ),

              const SizedBox(height: 14),

              if (isLoadingPackages && aiPackages.isNotEmpty)
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (packagesError != null && aiPackages.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Could not load packages.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else if (aiPackages.isEmpty)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      isLuxury ? 'No luxury packages found.' : 'No packages found.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: aiPackages.map((package) {
                      return _PackageCard(
                        title: package.title,
                        subtitle: _packageSubtitle(package),
                        price: '\$${package.price.toStringAsFixed(0)}',
                        rating: package.rating.toStringAsFixed(1),
                        tag: _packageTag(package),
                        imageAsset: package.imageAsset,
                        imageUrl: package.imageUrl,
                        onTap: () => _openPackage(package),
                        isLuxury: isLuxury,
                        isNight: isNight,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ModeButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final String selectedMode;
  final VoidCallback onTap;

  const _ModeButton({
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.selectedMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLuxuryTheme = selectedMode == 'Luxury';
    final isNightTheme = selectedMode == 'Night';
    final isDarkTheme = isLuxuryTheme || isNightTheme;
    final accentColor = isLuxuryTheme
        ? const Color(0xFFE8C766)
        : isNightTheme
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);
    final inactiveBackground =
        isDarkTheme ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final inactiveColor =
        isDarkTheme ? const Color(0xFFB8B8D1) : const Color(0xFF6B7280);
    final inactiveBorder =
        isDarkTheme ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final selectedTextColor =
        isSelected && isLuxuryTheme ? const Color(0xFF111827) : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected
                ? isDarkTheme
                    ? null
                    : const Color(0xFF2563EB)
                : inactiveBackground,
            gradient: isSelected && isLuxuryTheme
                ? const LinearGradient(
                    colors: [
                      Color(0xFFE8C766),
                      Color(0xFFB8860B),
                    ],
                  )
                : isSelected && isNightTheme
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFA855F7),
                          Color(0xFFEC4899),
                        ],
                      )
                    : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? accentColor : inactiveBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedTextColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? selectedTextColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final bool isLuxury;
  final bool isNight;
  final VoidCallback onTap;

  const _InterestChip({
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.isLuxury,
    required this.isNight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFE879F9)
            : const Color(0xFF2563EB);
    final selectedBackground = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBackground
              : isLuxury || isNight
                  ? const Color(0xFF111827)
                  : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? selectedBackground
                : isLuxury
                    ? const Color(0xFFE8C766).withOpacity(0.45)
                    : isNight
                        ? const Color(0xFFA855F7).withOpacity(0.35)
                        : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? isLuxury
                      ? const Color(0xFF111827)
                      : Colors.white
                  : accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? isLuxury
                        ? const Color(0xFF111827)
                        : Colors.white
                    : accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final bool isLuxury;
  final bool isNight;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isLuxury || isNight ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _SuggestedPackageCard extends StatelessWidget {
  final AiPackageModel package;
  final String tag;
  final bool isLuxury;
  final bool isNight;
  final VoidCallback onTap;

  const _SuggestedPackageCard({
    required this.package,
    required this.tag,
    required this.isLuxury,
    required this.isNight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      package.city,
      package.country,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    final tags = [
      tag,
      package.mode,
      if (package.city.trim().isNotEmpty) package.city,
    ].where((value) => value.trim().isNotEmpty).take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: isLuxury || isNight ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.35)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.35)
                    : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLuxury || isNight ? 0.32 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 125,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: _SuggestedImage(
                  imageUrl: package.imageUrl,
                  imageAsset: package.imageAsset,
                  isLuxury: isLuxury,
                  isNight: isNight,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLuxury
                          ? 'Curated luxury package'
                          : isNight
                              ? 'Curated nightlife package'
                              : 'Suggested package',
                      style: TextStyle(
                        color: isLuxury
                            ? const Color(0xFFB8B8B8)
                            : isNight
                                ? const Color(0xFFB8B8D1)
                                : const Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLuxury || isNight
                            ? Colors.white
                            : const Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isLuxury
                              ? const Color(0xFFE8C766)
                              : isNight
                                  ? const Color(0xFFA855F7)
                                  : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location.isEmpty ? package.subtitle : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLuxury
                                  ? const Color(0xFFB8B8B8)
                                  : isNight
                                      ? const Color(0xFFB8B8D1)
                                      : const Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: tags.map((value) {
                        return _SmallTag(
                          text: value,
                          isLuxury: isLuxury,
                          isNight: isNight,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          '\$${package.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFA855F7)
                                    : const Color(0xFF16A34A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          package.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: isLuxury
                                ? const Color(0xFFB8B8B8)
                                : isNight
                                    ? const Color(0xFFB8B8D1)
                                    : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedImage extends StatelessWidget {
  final String? imageUrl;
  final String? imageAsset;
  final bool isLuxury;
  final bool isNight;

  const _SuggestedImage({
    required this.imageUrl,
    this.imageAsset,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = isLuxury
        ? 'assets/images/privatebavariantour.jpg'
        : isNight
            ? 'assets/images/justcavalli.jpg'
            : 'assets/images/baligetaway.png';

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            imageAsset?.isNotEmpty == true ? imageAsset! : fallbackAsset,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
        },
      );
    }

    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      fallbackAsset,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  final bool isLuxury;
  final bool isNight;

  const _SmallTag({
    required this.text,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLuxury
              ? const Color(0xFFE8C766).withOpacity(0.55)
              : isNight
                  ? const Color(0xFFA855F7).withOpacity(0.55)
                  : const Color(0xFF60A5FA),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isLuxury
              ? const Color(0xFFE8C766)
              : isNight
                  ? const Color(0xFFE879F9)
                  : const Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final String tag;
  final bool isLuxury;
  final bool isNight;
  final String? imageAsset;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _PackageCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.tag,
    required this.isLuxury,
    required this.isNight,
    this.imageAsset,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        height: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isLuxury
              ? const Color(0xFF0B1020)
              : isNight
                  ? const Color(0xFF111827)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.35)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.35)
                    : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLuxury || isNight ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 78,
              decoration: BoxDecoration(
                color: isLuxury || isNight ? const Color(0xFF0B1020) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          if (imageAsset != null && imageAsset!.isNotEmpty) {
                            return Image.asset(
                              imageAsset!,
                              width: double.infinity,
                              height: 78,
                              fit: BoxFit.cover,
                            );
                          }

                          return Center(
                            child: Icon(
                              isLuxury
                                  ? Icons.workspace_premium_outlined
                                  : isNight
                                      ? Icons.nightlife
                                      : Icons.travel_explore,
                              color: isLuxury
                                  ? const Color(0xFFE8C766)
                                  : isNight
                                      ? const Color(0xFFA855F7)
                                      : const Color(0xFF2563EB),
                              size: 36,
                            ),
                          );
                        },
                      ),
                    )
                  else if (imageAsset != null && imageAsset!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.asset(
                        imageAsset!,
                        width: double.infinity,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        isLuxury
                            ? Icons.workspace_premium_outlined
                            : isNight
                                ? Icons.nightlife
                                : Icons.travel_explore,
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFA855F7)
                                : const Color(0xFF2563EB),
                        size: 36,
                      ),
                    ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFA855F7)
                                : const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isLuxury ? const Color(0xFF111827) : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isLuxury || isNight ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isLuxury
                        ? const Color(0xFFB8B8B8)
                        : isNight
                            ? const Color(0xFFB8B8D1)
                            : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFE879F9)
                                : const Color(0xFF16A34A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLuxury
                            ? const Color(0xFFB8B8B8)
                            : isNight
                                ? const Color(0xFFB8B8D1)
                                : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
