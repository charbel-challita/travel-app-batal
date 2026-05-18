import 'dart:math';

import 'package:flutter/material.dart';

import '../models/ai_package_model.dart';
import '../models/place_model.dart';
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

  List<AiPackageModel> aiPackages = [];
  bool isLoadingPackages = false;
  String? packagesError;
  List<PlaceModel> nightClubs = [];
  bool isLoadingNightClubs = false;
  String? nightClubsError;

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

    if (widget.selectedMode == 'Night') {
      _loadNightClubs();
    } else {
      _loadAiPackages();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMode != widget.selectedMode) {
      if (widget.selectedMode == 'Night') {
        _loadNightClubs();
      } else {
        _loadAiPackages();
      }
    }
  }

  Future<void> _loadAiPackages() async {
    setState(() {
      isLoadingPackages = true;
      packagesError = null;
    });

    try {
      final packages = await _apiService.getAiPackages(
        mode: widget.selectedMode,
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

  Future<void> _loadNightClubs() async {
    setState(() {
      isLoadingNightClubs = true;
      nightClubsError = null;
    });

    try {
      final clubs = await _apiService.getTravelItems(
        type: 'nightlife',
        includeImages: true,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        nightClubs = clubs;
        isLoadingNightClubs = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        nightClubs = [];
        nightClubsError = error.toString();
        isLoadingNightClubs = false;
      });
    }
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
                      child: Text(
                        isLuxury
                            ? 'Search private tours, villas, or premium stays...'
                            : isNight
                                ? 'Search clubs, bars, or cities...'
                                : 'Search cities, packages, or interests...',
                        style: TextStyle(
                          color: isLuxury || isNight
                              ? secondaryTextColor
                              : const Color(0xFFB0B7C3),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      color: isLuxury || isNight ? accentColor : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
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
                  children: [
                    _InterestChip(
                      text: isLuxury
                          ? 'Private'
                          : isNight
                              ? 'Clubs'
                              : 'Nature',
                      icon: isLuxury
                          ? Icons.lock_outline
                          : isNight
                              ? Icons.nightlife
                              : Icons.park,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _InterestChip(
                      text: isLuxury
                          ? 'Fine dining'
                          : isNight
                              ? 'Bars'
                              : 'Adventure',
                      icon: isLuxury
                          ? Icons.restaurant_menu
                          : isNight
                              ? Icons.local_bar
                              : Icons.hiking,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _InterestChip(
                      text: isLuxury
                          ? 'Scenic flights'
                          : isNight
                              ? 'Rooftops'
                              : 'Culture',
                      icon: isLuxury
                          ? Icons.flight_takeoff
                          : isNight
                              ? Icons.apartment
                              : Icons.account_balance,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _InterestChip(
                      text: isLuxury
                          ? 'Exclusive stays'
                          : isNight
                              ? 'Live music'
                              : 'Beach',
                      icon: isLuxury
                          ? Icons.villa_outlined
                          : isNight
                              ? Icons.music_note
                              : Icons.beach_access,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                  ],
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

              _SuggestedCard(
                isLuxury: isLuxury,
                isNight: isNight,
                selectedMode: widget.selectedMode,
              ),

              const SizedBox(height: 26),

              _SectionHeader(
                title: isNight ? 'Most popular clubs' : 'Ready-made packages',
                actionText: 'See all',
                isLuxury: isLuxury,
                isNight: isNight,
              ),

              const SizedBox(height: 14),

              if (isNight)
                _buildNightClubsSection(
                  secondaryTextColor: secondaryTextColor,
                )
              else if (isLoadingPackages)
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
                        subtitle: package.subtitle,
                        price: '\$${package.price.toStringAsFixed(0)}',
                        rating: package.rating.toStringAsFixed(1),
                        tag: package.tag,
                        imageAsset: package.imageAsset,
                        imageUrl: package.imageUrl,
                        onTap: () {
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
                        },
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

  Widget _buildNightClubsSection({
    required Color secondaryTextColor,
  }) {
    if (isLoadingNightClubs) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (nightClubsError != null && nightClubs.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Could not load clubs.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (nightClubs.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No clubs found.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: nightClubs.take(10).map((club) {
          return _PackageCard(
            title: club.name,
            subtitle: '${club.city}, ${club.country}',
            price: '\$${club.cost.toStringAsFixed(0)}',
            rating: club.rating.toStringAsFixed(1),
            tag: club.category.isNotEmpty ? club.category : 'Nightlife',
            imageUrl: club.primaryThumbnailUrl ?? club.primaryImageUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationDetailsScreen(
                    destination: club.name,
                    country: club.country,
                    selectedMode: widget.selectedMode,
                    place: club,
                  ),
                ),
              );
            },
            isLuxury: false,
            isNight: true,
          );
        }).toList(),
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
  final bool isLuxury;
  final bool isNight;

  const _InterestChip({
    required this.text,
    required this.icon,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: isLuxury || isNight ? const Color(0xFF111827) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLuxury
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
            color: isLuxury
                ? const Color(0xFFE8C766)
                : isNight
                    ? const Color(0xFFE879F9)
                    : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isLuxury
                  ? const Color(0xFFE8C766)
                  : isNight
                      ? const Color(0xFFE879F9)
                      : const Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
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

class _SuggestedCard extends StatefulWidget {
  final bool isLuxury;
  final bool isNight;
  final String selectedMode;

  const _SuggestedCard({
    required this.isLuxury,
    required this.isNight,
    required this.selectedMode,
  });

  @override
  State<_SuggestedCard> createState() => _SuggestedCardState();
}

class _SuggestedCardState extends State<_SuggestedCard> {
  final ApiService _apiService = ApiService();

  PlaceModel? suggestedPlace;
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedPlace();
  }

  @override
  void didUpdateWidget(covariant _SuggestedCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMode != widget.selectedMode) {
      _loadSuggestedPlace();
    }
  }

  Future<void> _loadSuggestedPlace() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final places = await _apiService.getTravelItems(
        type: widget.isNight ? 'nightlife' : null,
        budgetLevel: widget.isLuxury ? 'luxury' : null,
        includeImages: true,
        limit: 20,
      );

      if (!mounted) return;

      if (places.isEmpty) {
        setState(() {
          suggestedPlace = null;
          isLoading = false;
          hasError = true;
        });
        return;
      }

      final randomPlace = places[Random().nextInt(places.length)];

      setState(() {
        suggestedPlace = randomPlace;
        isLoading = false;
        hasError = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        suggestedPlace = null;
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _openDetails(BuildContext context) {
    final place = suggestedPlace;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationDetailsScreen(
          destination: place?.name ??
              (widget.isLuxury
                  ? 'Private Bavarian Alps Tour'
                  : widget.isNight
                      ? 'Just Cavalli Club'
                      : 'Island Escape Getaway'),
          country: place?.country ??
              (widget.isLuxury
                  ? 'Germany'
                  : widget.isNight
                      ? 'UAE'
                      : 'Indonesia'),
          selectedMode: widget.selectedMode,
          place: place,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLuxury = widget.isLuxury;
    final isNight = widget.isNight;
    final place = suggestedPlace;

    final title = place?.name ??
        (isLuxury
            ? 'Private Bavarian Alps Tour'
            : isNight
                ? 'Just Cavalli Club'
                : 'Island Escape Getaway');

    final location = place == null
        ? isLuxury
            ? 'Bavaria, Germany'
            : isNight
                ? 'Dubai, UAE'
                : 'Bali, Indonesia'
        : '${place.city}, ${place.country}';

    final duration = place == null
        ? isLuxury
            ? '8h'
            : isNight
                ? '5h'
                : '24h'
        : place.type == 'hotel'
            ? 'per night'
            : '${place.durationHours.toStringAsFixed(1)}h';

    final price = place == null
        ? isLuxury
            ? '\$1480'
            : isNight
                ? '\$\$\$'
                : '\$680'
        : '\$${place.cost.toStringAsFixed(0)}';

    final rating = place?.rating.toStringAsFixed(1) ??
        (isLuxury
            ? '4.9'
            : isNight
                ? '4.8'
                : '4.8');

    final imageUrl = place?.primaryThumbnailUrl ?? place?.primaryImageUrl;

    final tags = _tagsForPlace(
      place,
      isLuxury: isLuxury,
      isNight: isNight,
    );

    return GestureDetector(
      onTap: () => _openDetails(context),
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
                  imageUrl: imageUrl,
                  isLuxury: isLuxury,
                  isNight: isNight,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: isLoading && !isLuxury && !isNight
                    ? const Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLuxury
                                ? 'Curated for private scenic travel'
                                : isNight
                                    ? 'Because you like clubs + nightlife'
                                    : 'Suggested for you',
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
                            title,
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
                                  location,
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
                            children: tags.take(3).map((tag) {
                              return _SmallTag(
                                text: tag,
                                isLuxury: isLuxury,
                                isNight: isNight,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: isLuxury
                                    ? const Color(0xFFB8B8B8)
                                    : isNight
                                        ? const Color(0xFFB8B8D1)
                                        : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                duration,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isLuxury
                                      ? const Color(0xFFB8B8B8)
                                      : isNight
                                          ? const Color(0xFFB8B8D1)
                                          : const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                price,
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
                                rating,
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

  List<String> _tagsForPlace(
    PlaceModel? place, {
    required bool isLuxury,
    required bool isNight,
  }) {
    if (place == null) {
      if (isLuxury) return ['Private', 'Nature', 'Luxury'];
      if (isNight) return ['Club', 'Nightlife', 'VIP'];
      return ['Beach', 'Nature', 'Culture'];
    }

    final tags = <String>[];

    if (place.category.trim().isNotEmpty) {
      tags.add(_formatTag(place.category));
    }

    for (final tag in place.interestTags) {
      final formatted = _formatTag(tag);
      if (formatted.isNotEmpty && !tags.contains(formatted)) {
        tags.add(formatted);
      }
      if (tags.length == 3) break;
    }

    if (tags.isEmpty) {
      tags.add(_formatTag(place.type));
    }

    if (isLuxury && !tags.contains('Luxury')) {
      tags.add('Luxury');
    }

    if (isNight && !tags.contains('Nightlife')) {
      tags.add('Nightlife');
    }

    return tags.take(3).toList();
  }

  String _formatTag(String value) {
    final cleaned = value.trim().replaceAll('_', ' ');
    if (cleaned.isEmpty) return cleaned;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}

class _SuggestedImage extends StatelessWidget {
  final String? imageUrl;
  final bool isLuxury;
  final bool isNight;

  const _SuggestedImage({
    required this.imageUrl,
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
            fallbackAsset,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
        },
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
