import 'package:flutter/material.dart';

import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  final String selectedMode;

  const TripsScreen({
    super.key,
    this.selectedMode = 'Casual',
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String selectedTab = 'Ongoing';

  final List<String> tabs = ['Ongoing', 'Upcoming', 'Saved', 'Past'];

  final Map<String, List<TripItem>> tripsByTab = {
    'Ongoing': [
      TripItem(
        title: 'Bali Culture & Beach Escape',
        location: 'Bali, Indonesia',
        date: 'Today',
        duration: '7h',
        status: 'Ongoing',
        action: 'View itinerary',
        interests: ['Culture', 'Beach', 'Relax'],
        icon: Icons.beach_access,
      ),
    ],
    'Upcoming': [
      TripItem(
        title: 'Rome Culture Weekend',
        location: 'Rome, Italy',
        date: 'June 12',
        duration: '3 days',
        status: 'Upcoming',
        action: 'View details',
        interests: ['Culture', 'Food', 'History'],
        icon: Icons.account_balance_outlined,
      ),
      TripItem(
        title: 'Tokyo Discovery Tour',
        location: 'Tokyo, Japan',
        date: 'July 4',
        duration: '7 days',
        status: 'Upcoming',
        action: 'View details',
        interests: ['Food', 'Culture', 'Adventure'],
        icon: Icons.travel_explore,
      ),
    ],
    'Saved': [
      TripItem(
        title: 'Dubai Luxury Break',
        location: 'Dubai, UAE',
        date: 'Saved plan',
        duration: '4 days',
        status: 'Saved',
        action: 'Open plan',
        interests: ['Luxury', 'Shopping', 'City'],
        icon: Icons.location_city_outlined,
      ),
      TripItem(
        title: 'Just Cavalli Night Plan',
        location: 'Dubai, UAE',
        date: 'Saved plan',
        duration: '4.5h',
        status: 'Saved',
        action: 'Choose club',
        interests: ['Club', 'Nightlife', 'VIP'],
        icon: Icons.nightlife_outlined,
      ),
    ],
    'Past': [
      TripItem(
        title: 'Private Bavarian Alps Escape',
        location: 'Bavaria, Germany',
        date: 'May 20',
        duration: '6h',
        status: 'Completed',
        action: 'View memories',
        interests: ['Private', 'Scenic', 'Luxury'],
        icon: Icons.landscape_outlined,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final currentTrips = tripsByTab[selectedTab] ?? [];
    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';

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
    final primaryTextColor = isLuxury
        ? const Color(0xFFFFF8E1)
        : isNight
            ? Colors.white
            : const Color(0xFF111827);
    final secondaryTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF64748B);
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
                'Trips',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  _TripSummaryCard(
                    label: 'Ongoing',
                    number: '1',
                    icon: Icons.sync,
                    color: const Color(0xFF10B981),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Saved',
                    number: '6',
                    icon: Icons.bookmark,
                    color: const Color(0xFF2563EB),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Past',
                    number: '18',
                    icon: Icons.history,
                    color: const Color(0xFFF59E0B),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Container(
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLuxury || isNight ? cardColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLuxury || isNight ? borderColor : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = selectedTab == tab;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? isLuxury
                                      ? const Color(0xFF111827)
                                      : Colors.white
                                  : secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 26),

              if (currentTrips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No trips here yet.',
                      style: TextStyle(
                        color: isLuxury
                            ? const Color(0xFFB8B8B8)
                            : isNight
                                ? const Color(0xFFB8B8D1)
                            : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: currentTrips.map((trip) {
                    return _TripLargeCard(
                      trip: trip,
                      isLuxury: isLuxury,
                      isNight: isNight,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripItem {
  final String title;
  final String location;
  final String date;
  final String duration;
  final String status;
  final String action;
  final List<String> interests;
  final IconData icon;

  TripItem({
    required this.title,
    required this.location,
    required this.date,
    required this.duration,
    required this.status,
    required this.action,
    required this.interests,
    required this.icon,
  });
}

class _TripSummaryCard extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;
  final bool isLuxury;
  final bool isNight;

  const _TripSummaryCard({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 88,
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.13),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLuxury
                          ? const Color(0xFFB8B8B8)
                          : isNight
                              ? const Color(0xFFB8B8D1)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
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

class _TripLargeCard extends StatelessWidget {
  final TripItem trip;
  final bool isLuxury;
  final bool isNight;

  const _TripLargeCard({
    required this.trip,
    required this.isLuxury,
    required this.isNight,
  });

  Color get statusColor {
    if (trip.status == 'Ongoing') return const Color(0xFF10B981);
    if (trip.status == 'Completed') return const Color(0xFFF59E0B);
    if (trip.status == 'Upcoming') return const Color(0xFF2563EB);
    return const Color(0xFF7C3AED);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailsScreen(
              title: trip.title,
              location: trip.location,
              status: trip.status,
            ),
          ),
        );
      },
      child: Container(
        height: 255,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
                    : [
                        statusColor.withOpacity(0.95),
                        const Color(0xFF111827),
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isLuxury
                ? const Color(0xFFE8C766).withOpacity(0.35)
                : isNight
                    ? const Color(0xFFA855F7).withOpacity(0.35)
                    : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: isLuxury
                  ? Colors.black.withOpacity(0.35)
                  : isNight
                      ? Colors.black.withOpacity(0.35)
                  : statusColor.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                trip.icon,
                size: 140,
                color: Colors.white.withOpacity(0.12),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFA855F7)
                            : Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        trip.status,
                        style: TextStyle(
                          color: isLuxury
                              ? const Color(0xFF111827)
                              : isNight
                                  ? Colors.white
                                  : statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${trip.date} • ${trip.duration}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: trip.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isLuxury || isNight
                              ? const Color(0xFF111827)
                              : Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFE879F9)
                                : statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        trip.action,
                        style: TextStyle(
                          color: isLuxury
                              ? const Color(0xFFE8C766)
                              : isNight
                                  ? const Color(0xFFE879F9)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.chevron_right,
                        color: isLuxury
                            ? const Color(0xFFE8C766)
                            : isNight
                                ? const Color(0xFFE879F9)
                            : Colors.white,
                        size: 20,
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
