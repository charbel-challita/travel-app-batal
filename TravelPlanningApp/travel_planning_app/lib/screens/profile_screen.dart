import 'package:flutter/material.dart';

import 'profile_option_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String selectedMode;

  const ProfileScreen({
    super.key,
    this.selectedMode = 'Casual',
  });

  @override
  Widget build(BuildContext context) {
    final isLuxury = selectedMode == 'Luxury';
    final isNight = selectedMode == 'Night';

    final backgroundColor = isLuxury
        ? const Color(0xFF030303)
        : isNight
            ? const Color(0xFF050818)
            : const Color(0xFFFDFDFD);
    final cardColor = isLuxury
        ? const Color(0xFF0B1020)
        : isNight
            ? const Color(0xFF111827)
            : Colors.white;
    final darkCardColor = isLuxury
        ? const Color(0xFF111827)
        : isNight
            ? const Color(0xFF1E1B4B)
            : const Color(0xFFEFF6FF);
    final primaryTextColor = isLuxury
        ? const Color(0xFFFFF8E1)
        : isNight
            ? Colors.white
            : const Color(0xFF111827);
    final secondaryTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF6B7280);
    final accentColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);
    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withOpacity(0.35)
        : isNight
            ? const Color(0xFFA855F7).withOpacity(0.35)
            : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLuxury
                        ? [
                            cardColor,
                            darkCardColor,
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isLuxury || isNight ? borderColor : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 74,
                      width: 74,
                      decoration: BoxDecoration(
                        color: isLuxury
                            ? accentColor.withOpacity(0.18)
                            : isNight
                                ? accentColor.withOpacity(0.18)
                            : Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: isLuxury || isNight ? accentColor : Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maria Tabet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'maria@example.com',
                            style: TextStyle(
                              color: isLuxury
                                  ? secondaryTextColor
                                  : isNight
                                      ? secondaryTextColor
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Casual traveler',
                            style: TextStyle(
                              color: isLuxury
                                  ? secondaryTextColor
                                  : isNight
                                      ? secondaryTextColor
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  _ProfileStatCard(
                    number: '6',
                    label: 'Saved trips',
                    icon: Icons.bookmark,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 12),
                  _ProfileStatCard(
                    number: '12',
                    label: 'Favorites',
                    icon: Icons.favorite,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 12),
                  _ProfileStatCard(
                    number: '18',
                    label: 'Past trips',
                    icon: Icons.history,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLuxury || isNight ? borderColor : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _TripTypeMiniCard(
                      title: 'Casual Trips',
                      number: '9',
                      emoji: '🌴',
                      color: const Color(0xFF2563EB),
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _TripTypeMiniCard(
                      title: 'Nightlife Trips',
                      number: '6',
                      emoji: '🍸',
                      color: const Color(0xFFC026D3),
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    _TripTypeMiniCard(
                      title: 'Luxury Trips',
                      number: '3',
                      emoji: '👑',
                      color: const Color(0xFFD97706),
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Favorite interests',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InterestPill(
                    text: 'Beach',
                    icon: Icons.beach_access,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  _InterestPill(
                    text: 'Culture',
                    icon: Icons.account_balance,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  _InterestPill(
                    text: 'Food',
                    icon: Icons.restaurant,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  _InterestPill(
                    text: 'Nature',
                    icon: Icons.park,
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Payments and bookings',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 14),

              _AccountOption(
                icon: Icons.credit_card,
                title: 'Payment methods',
                isLuxury: isLuxury,
                isNight: isNight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOptionScreen(
                        title: 'Payment methods',
                        icon: Icons.credit_card,
                        description:
                            'Manage saved cards, payment options, and billing details.',
                      ),
                    ),
                  );
                },
              ),
              _AccountOption(
                icon: Icons.receipt_long,
                title: 'Booking history',
                isLuxury: isLuxury,
                isNight: isNight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOptionScreen(
                        title: 'Booking history',
                        icon: Icons.receipt_long,
                        description:
                            'View your previous bookings and completed travel purchases.',
                      ),
                    ),
                  );
                },
              ),
              _AccountOption(
                icon: Icons.confirmation_number_outlined,
                title: 'Active bookings',
                isLuxury: isLuxury,
                isNight: isNight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOptionScreen(
                        title: 'Active bookings',
                        icon: Icons.confirmation_number_outlined,
                        description:
                            'See your current hotel, activity, and restaurant bookings.',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Account',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 14),

              _AccountOption(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                isLuxury: isLuxury,
                isNight: isNight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOptionScreen(
                        title: 'Edit profile',
                        icon: Icons.edit_outlined,
                        description:
                            'Update your name, email, profile photo, and travel preferences.',
                      ),
                    ),
                  );
                },
              ),
              _AccountOption(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                isLuxury: isLuxury,
                isNight: isNight,
              ),
              _AccountOption(
                icon: Icons.settings_outlined,
                title: 'Settings',
                isLuxury: isLuxury,
                isNight: isNight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileOptionScreen(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        description:
                            'Change app settings, notifications, and account preferences.',
                      ),
                    ),
                  );
                },
              ),
              _AccountOption(
                icon: Icons.logout,
                title: 'Log out',
                isDanger: true,
                isLuxury: isLuxury,
                isNight: isNight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final bool isLuxury;
  final bool isNight;

  const _ProfileStatCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLuxury || isNight ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.25)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.25)
                    : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLuxury
                  ? const Color(0xFFE8C766)
                  : isNight
                      ? const Color(0xFFA855F7)
                      : const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: TextStyle(
                color: isLuxury
                    ? const Color(0xFFE8C766)
                    : isNight
                        ? const Color(0xFFA855F7)
                        : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLuxury
                    ? const Color(0xFFB8B8B8)
                    : isNight
                        ? const Color(0xFFB8B8D1)
                        : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLuxury;
  final bool isNight;

  const _InterestPill({
    required this.text,
    required this.icon,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isLuxury || isNight ? const Color(0xFF111827) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLuxury
              ? const Color(0xFFE8C766).withOpacity(0.35)
              : isNight
                  ? const Color(0xFFA855F7).withOpacity(0.35)
                  : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isLuxury
                ? const Color(0xFFE8C766)
                : isNight
                    ? const Color(0xFFA855F7)
                    : const Color(0xFF2563EB),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isLuxury
                  ? const Color(0xFFE8C766)
                  : isNight
                      ? const Color(0xFFA855F7)
                      : const Color(0xFF2563EB),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDanger;
  final bool isLuxury;
  final bool isNight;
  final VoidCallback? onTap;

  const _AccountOption({
    required this.icon,
    required this.title,
    this.isDanger = false,
    this.isLuxury = false,
    this.isNight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? const Color(0xFFEF4444)
        : isLuxury
            ? const Color(0xFFFFF8E1)
            : isNight
                ? Colors.white
            : const Color(0xFF111827);
    final iconColor = isDanger
        ? const Color(0xFFEF4444)
        : isLuxury
            ? const Color(0xFFE8C766)
            : isNight
                ? const Color(0xFFA855F7)
            : const Color(0xFF111827);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isLuxury || isNight ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.25)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.25)
                    : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDanger
                  ? color
                  : isLuxury
                      ? const Color(0xFFE8C766)
                      : isNight
                          ? const Color(0xFFA855F7)
                      : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTypeMiniCard extends StatelessWidget {
  final String title;
  final String number;
  final String emoji;
  final Color color;
  final bool isLuxury;
  final bool isNight;

  const _TripTypeMiniCard({
    required this.title,
    required this.number,
    required this.emoji,
    required this.color,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : color;

    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: displayColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: displayColor.withOpacity(0.12),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                number,
                style: TextStyle(
                  color: displayColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
