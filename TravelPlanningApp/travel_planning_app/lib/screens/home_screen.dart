import 'package:flutter/material.dart';

import 'destination_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final VoidCallback? onOpenAiPlanner;

  const HomeScreen({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.onOpenAiPlanner,
  });

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
  Widget build(BuildContext context) {
    final isLuxury = selectedMode == 'Luxury';
    final isNight = selectedMode == 'Night';
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
                    isSelected: selectedMode == 'Casual',
                    selectedMode: selectedMode,
                    onTap: () => onModeChanged('Casual'),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    text: 'Luxury',
                    icon: Icons.diamond_outlined,
                    isSelected: selectedMode == 'Luxury',
                    selectedMode: selectedMode,
                    onTap: () => onModeChanged('Luxury'),
                  ),
                  const SizedBox(width: 12),
                  _ModeButton(
                    text: 'Night',
                    icon: Icons.nightlight_round,
                    isSelected: selectedMode == 'Night',
                    selectedMode: selectedMode,
                    onTap: () => onModeChanged('Night'),
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
                              onPressed: onOpenAiPlanner,
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailsScreen(
                        destination: isLuxury
                            ? 'Private Bavarian Alps Tour'
                            : isNight
                                ? 'Just Cavalli Club'
                                : 'Island Escape Getaway',
                        country: isLuxury
                            ? 'Germany'
                            : isNight
                                ? 'UAE'
                                : 'Indonesia',
                        selectedMode: selectedMode,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 26),

              _SectionHeader(
                title: isNight ? 'Most popular clubs' : 'Ready-made packages',
                actionText: 'See all',
                isLuxury: isLuxury,
                isNight: isNight,
              ),

              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PackageCard(
                      title: isNight
                          ? 'Marseille Red Club'
                          : isLuxury
                              ? 'Halong Bay Seaplane Tour'
                              : 'Rome First-Time Tour',
                      subtitle: isNight
                          ? 'Waterfront beats'
                          : isLuxury
                              ? 'Skyline views & private cruise'
                              : 'The Eternal City',
                      price: isNight
                          ? '\$\$\$'
                          : isLuxury
                              ? '\$980'
                              : '\$320',
                      rating: isNight
                          ? '4.6'
                          : isLuxury
                              ? '4.9'
                              : '4.7',
                      tag: isNight
                          ? 'Trending'
                          : isLuxury
                              ? 'Private'
                              : 'Popular',
                      imageAsset: isLuxury
                          ? 'assets/images/halongbay.jpg'
                          : isNight
                              ? null
                              : 'assets/images/rome.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailsScreen(
                              destination: isLuxury
                                  ? 'Halong Bay Seaplane Tour'
                                  : isNight
                                      ? 'Marseille Red Club'
                                      : 'Rome First-Time Tour',
                              country: isLuxury
                                  ? 'Vietnam'
                                  : isNight
                                      ? 'France'
                                      : 'Italy',
                              selectedMode: selectedMode,
                            ),
                          ),
                        );
                      },
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _PackageCard(
                      title: isNight
                          ? 'Club Ibiza Nightclub'
                          : isLuxury
                              ? 'Dubai Elite Yacht Escape'
                              : 'Dubai City Highlights',
                      subtitle: isNight
                          ? 'Island party energy'
                          : isLuxury
                              ? 'Hotel, yacht & fine dining'
                              : 'Modern wonders await',
                      price: isNight
                          ? '\$\$\$'
                          : isLuxury
                              ? '\$1850'
                              : '\$290',
                      rating: isNight
                          ? '4.7'
                          : isLuxury
                              ? '4.8'
                              : '4.6',
                      tag: isNight
                          ? 'Popular'
                          : isLuxury
                              ? 'VIP'
                              : 'Trending',
                      imageAsset: isLuxury
                          ? 'assets/images/dubaiyacht.jpg'
                          : isNight
                              ? null
                              : 'assets/images/dubai.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailsScreen(
                              destination: isLuxury
                                  ? 'Dubai Elite Yacht Escape'
                                  : isNight
                                      ? 'Club Ibiza Nightclub'
                                      : 'Dubai City Highlights',
                              country: isLuxury
                                  ? 'UAE'
                                  : isNight
                                      ? 'Spain'
                                      : 'UAE',
                              selectedMode: selectedMode,
                            ),
                          ),
                        );
                      },
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _PackageCard(
                      title: isNight
                          ? 'Salento Dance Club'
                          : isLuxury
                              ? 'Private Island Stay'
                              : 'Tokyo Discovery Tour',
                      subtitle: isNight
                          ? 'Latin dance nights'
                          : isLuxury
                              ? 'Private villa, yacht & sunset dining'
                              : 'Tradition meets tomorrow',
                      price: isNight
                          ? '\$\$'
                          : isLuxury
                              ? '\$3450'
                              : '\$340',
                      rating: isNight ? '4.5' : '4.8',
                      tag: isNight
                          ? 'New'
                          : isLuxury
                              ? 'Luxury'
                              : 'Sale',
                      imageAsset: isLuxury
                          ? 'assets/images/prvtislandstay.webp'
                          : isNight
                              ? null
                              : 'assets/images/tokyo.webp',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailsScreen(
                              destination: isLuxury
                                  ? 'Private Island Stay'
                                  : isNight
                                      ? 'Salento Dance Club'
                                      : 'Tokyo Discovery Tour',
                              country: isLuxury
                                  ? 'Maldives'
                                  : isNight
                                      ? 'Colombia'
                                      : 'Japan',
                              selectedMode: selectedMode,
                            ),
                          ),
                        );
                      },
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                  ],
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

class _SuggestedCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLuxury;
  final bool isNight;

  const _SuggestedCard({
    required this.onTap,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withOpacity(isLuxury ? 0.32 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 125,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                image: DecorationImage(
                  image: AssetImage(
                    isLuxury
                        ? 'assets/images/privatebavariantour.jpg'
                        : isNight
                            ? 'assets/images/justcavalli.jpg'
                            : 'assets/images/baligetaway.png',
                  ),
                  fit: BoxFit.cover,
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
                          ? 'Curated for private scenic travel'
                          : isNight
                              ? 'Because you like clubs + nightlife'
                              : 'Because you like nature + beaches',
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
                      isLuxury
                          ? 'Private Bavarian Alps Tour'
                          : isNight
                              ? 'Just Cavalli Club'
                              : 'Island Escape Getaway',
                      style: TextStyle(
                        color: isLuxury || isNight ? Colors.white : const Color(0xFF111827),
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
                        Text(
                          isLuxury
                              ? 'Bavaria, Germany'
                              : isNight
                                  ? 'Dubai, UAE'
                                  : 'Bali, Indonesia',
                          style: TextStyle(
                            color: isLuxury
                                ? const Color(0xFFB8B8B8)
                                : isNight
                                    ? const Color(0xFFB8B8D1)
                                    : const Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _SmallTag(
                          text: isLuxury
                              ? 'Private'
                              : isNight
                                  ? 'Luxury'
                                  : 'Beach',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                        _SmallTag(
                          text: isNight ? 'Club' : 'Nature',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                        _SmallTag(
                          text: isLuxury
                              ? 'Luxury'
                              : isNight
                                  ? 'Nightlife'
                                  : 'Culture',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                      ],
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
                          isLuxury ? '8h' : isNight ? '5h' : '24h',
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
                          isLuxury
                              ? '\$1480'
                              : isNight
                                  ? '\$\$\$'
                                  : '\$680',
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
                        const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          isLuxury ? '4.9' : '4.8',
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
                  if (imageAsset != null)
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
                        isLuxury ? Icons.workspace_premium_outlined : Icons.travel_explore,
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
