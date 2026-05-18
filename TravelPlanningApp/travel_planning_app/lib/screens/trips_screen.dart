import 'package:flutter/material.dart';

import '../services/api_service.dart';
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
  final ApiService _apiService = ApiService();
  final List<String> tabs = ['Ongoing', 'Favorites', 'Saved', 'Past'];

  String selectedTab = 'Ongoing';
  bool isLoading = false;
  String? errorMessage;
  List<TripItem> currentTrips = [];
  Map<String, int> counts = {
    'ongoing': 0,
    'favorites': 0,
    'saved': 0,
    'past': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  String get _selectedStatus => _statusForTab(selectedTab);

  String _statusForTab(String tab) {
    if (tab == 'Saved') return 'saved';
    if (tab == 'Past') return 'past';
    return 'ongoing';
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedCounts = await _apiService.getTripCounts();
      final loadedFavorites = await _apiService.getFavorites();
      final loadedTrips = selectedTab == 'Favorites'
          ? loadedFavorites
          : await _apiService.getTrips(status: _selectedStatus);

      if (!mounted) return;

      setState(() {
        counts = {
          ...loadedCounts,
          'favorites': loadedFavorites.length,
        };
        currentTrips = loadedTrips
            .map<TripItem>(
              selectedTab == 'Favorites'
                  ? TripItem.fromFavoriteJson
                  : TripItem.fromJson,
            )
            .toList(growable: false);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = ApiService.cleanErrorMessage(error);
        currentTrips = [];
        isLoading = false;
      });
    }
  }

  Future<void> _updateTripStatus(TripItem trip, String status) async {
    try {
      await _apiService.updateTripStatus(trip.id, status);
      await _loadTrips();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.cleanErrorMessage(error))),
      );
    }
  }

  String get _emptyMessage {
    if (selectedTab == 'Favorites') return 'No favorites yet.';
    if (selectedTab == 'Saved') return 'No saved trips yet.';
    if (selectedTab == 'Past') return 'No past trips yet.';
    return 'No ongoing trips yet.';
  }

  @override
  Widget build(BuildContext context) {
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
                    number: '${counts['ongoing'] ?? 0}',
                    icon: Icons.sync,
                    color: const Color(0xFF10B981),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Favorites',
                    number: '${counts['favorites'] ?? 0}',
                    icon: Icons.favorite,
                    color: const Color(0xFFEC4899),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Saved',
                    number: '${counts['saved'] ?? 0}',
                    icon: Icons.bookmark,
                    color: const Color(0xFF2563EB),
                    isLuxury: isLuxury,
                    isNight: isNight,
                  ),
                  const SizedBox(width: 10),
                  _TripSummaryCard(
                    label: 'Past',
                    number: '${counts['past'] ?? 0}',
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
                          if (selectedTab == tab) return;

                          setState(() {
                            selectedTab = tab;
                          });
                          _loadTrips();
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
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else if (currentTrips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      _emptyMessage,
                      style: TextStyle(
                        color: secondaryTextColor,
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
                      onAction: trip.status == 'saved'
                          ? () => _updateTripStatus(trip, 'ongoing')
                          : trip.status == 'ongoing'
                              ? () => _updateTripStatus(trip, 'past')
                              : null,
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
  final String id;
  final String title;
  final String location;
  final String duration;
  final String status;
  final String action;
  final List<String> interests;
  final IconData icon;

  TripItem({
    required this.id,
    required this.title,
    required this.location,
    required this.duration,
    required this.status,
    required this.action,
    required this.interests,
    required this.icon,
  });

  factory TripItem.fromJson(Map<String, dynamic> json) {
    final status = _readString(json['status'], fallback: 'saved');

    return TripItem(
      id: _readString(json['_id'] ?? json['id']),
      title: _readString(json['title'], fallback: 'Untitled trip'),
      location: _readString(json['location']),
      duration: _readString(json['duration'], fallback: 'Trip plan'),
      status: status,
      action: _actionForStatus(status),
      interests: _readStringList(json['tags']),
      icon: _iconForStatus(status),
    );
  }

  factory TripItem.fromFavoriteJson(Map<String, dynamic> json) {
    final itemType = _readString(json['item_type'], fallback: 'Favorite');

    return TripItem(
      id: _readString(json['_id'] ?? json['id']),
      title: _readString(json['title'], fallback: 'Untitled favorite'),
      location: _readString(json['location']),
      duration: _readString(json['duration'], fallback: 'Favorite'),
      status: 'favorite',
      action: 'View favorite',
      interests: _readStringList(json['tags']).isEmpty
          ? [itemType]
          : _readStringList(json['tags']),
      icon: Icons.favorite,
    );
  }

  String get displayStatus {
    if (status == 'ongoing') return 'Ongoing';
    if (status == 'past') return 'Past';
    if (status == 'favorite') return 'Favorite';
    return 'Saved';
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  static String _actionForStatus(String status) {
    if (status == 'saved') return 'Start Trip';
    if (status == 'ongoing') return 'Mark as Past';
    return 'View memories';
  }

  static IconData _iconForStatus(String status) {
    if (status == 'saved') return Icons.bookmark;
    if (status == 'past') return Icons.history;
    return Icons.sync;
  }
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
  final VoidCallback? onAction;

  const _TripLargeCard({
    required this.trip,
    required this.isLuxury,
    required this.isNight,
    this.onAction,
  });

  Color get statusColor {
    if (trip.status == 'ongoing') return const Color(0xFF10B981);
    if (trip.status == 'past') return const Color(0xFFF59E0B);
    if (trip.status == 'favorite') return const Color(0xFFEC4899);
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
              status: trip.displayStatus,
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
                        trip.displayStatus,
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
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        trip.duration,
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
                    children: (trip.interests.isEmpty
                            ? [trip.displayStatus]
                            : trip.interests)
                        .map((interest) {
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
                      if (onAction == null)
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
                        )
                      else
                        ElevatedButton(
                          onPressed: onAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLuxury
                                ? const Color(0xFFE8C766)
                                : isNight
                                    ? const Color(0xFFA855F7)
                                    : Colors.white,
                            foregroundColor: isLuxury || !isNight
                                ? const Color(0xFF111827)
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            trip.action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
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
