import 'package:flutter/material.dart';

import 'trip_details_screen.dart';

class AiPlannerScreen extends StatefulWidget {
  final String selectedMode;

  const AiPlannerScreen({
    super.key,
    this.selectedMode = 'Casual',
  });

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController customBudgetController = TextEditingController();

  int tripDays = 1;
  String selectedBudget = 'Mid-range';
  String selectedTravelGroup = 'Friends';

  final List<String> selectedInterests = ['Beach', 'Nature'];

  final List<String> interests = [
    'Nature',
    'Culture',
    'Beach',
    'Food',
    'Shopping',
    'Adventure',
    'Luxury',
    'Relax',
    'History',
    'Hidden gems',
  ];

  final List<String> travelGroups = [
    'Solo',
    'Friends',
    'Couple',
    'Family',
  ];

  void toggleInterest(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }
    });
  }

  void selectBudget(String budget) {
    setState(() {
      selectedBudget = budget;
    });
  }

  void increaseDays() {
    setState(() {
      tripDays++;
    });
  }

  void decreaseDays() {
    if (tripDays > 1) {
      setState(() {
        tripDays--;
      });
    }
  }

  @override
  void dispose() {
    destinationController.dispose();
    customBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomBudget = selectedBudget == 'Custom';
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
            ? const Color(0xFF0B1020)
            : const Color(0xFFF4F4F5);
    final inputColor = isLuxury || isNight ? const Color(0xFF111827) : Colors.white;
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
                isLuxury ? 'Build your luxury AI trip' : 'Build your AI trip',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLuxury
                    ? 'Choose your premium destination, budget, duration and preferences. AI will craft a luxury trip plan.'
                    : 'Choose your destination, budget, duration and interests. AI will use these choices to create your trip plan.',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isLuxury || isNight ? borderColor : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLuxury || isNight ? 0.35 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallLabel(
                      icon: Icons.location_on_outlined,
                      text: 'Destination',
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        hintText: isLuxury
                            ? 'Search premium city or destination'
                            : 'Search country or city',
                        hintStyle: TextStyle(
                          color: isLuxury || isNight
                              ? const Color(0xFFB8B8B8)
                              : const Color(0xFF9CA3AF),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: accentColor,
                        ),
                        filled: true,
                        fillColor: inputColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        color: isLuxury || isNight ? Colors.white : const Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 22),

                    _SmallLabel(
                      icon: Icons.calendar_today_outlined,
                      text: 'Duration',
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 10),

                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isLuxury || isNight ? borderColor : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: decreaseDays,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: accentColor,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$tripDays ${tripDays == 1 ? 'day' : 'days'}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: increaseDays,
                            icon: const Icon(Icons.add_circle_outline),
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),

                    if (!isLuxury) ...[
                      const SizedBox(height: 22),

                      _SmallLabel(
                        icon: Icons.account_balance_wallet_outlined,
                        text: 'Budget',
                        isLuxury: isLuxury,
                        isNight: isNight,
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ChipButton(
                            text: 'Low',
                            isSelected: selectedBudget == 'Low',
                            isLuxury: isLuxury,
                            isNight: isNight,
                            onTap: () => selectBudget('Low'),
                          ),
                          _ChipButton(
                            text: 'Mid-range',
                            isSelected: selectedBudget == 'Mid-range',
                            isLuxury: isLuxury,
                            isNight: isNight,
                            onTap: () => selectBudget('Mid-range'),
                          ),
                          _ChipButton(
                            text: 'Flexible',
                            isSelected: selectedBudget == 'Flexible',
                            isLuxury: isLuxury,
                            isNight: isNight,
                            onTap: () => selectBudget('Flexible'),
                          ),
                          _ChipButton(
                            text: 'Custom',
                            isSelected: selectedBudget == 'Custom',
                            isLuxury: isLuxury,
                            isNight: isNight,
                            onTap: () => selectBudget('Custom'),
                          ),
                        ],
                      ),

                      if (isCustomBudget) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customBudgetController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isNight ? Colors.white : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your budget, example: 800',
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: accentColor,
                            ),
                            filled: true,
                            fillColor: inputColor,
                            hintStyle: TextStyle(
                              color: isNight
                                  ? const Color(0xFFB8B8D1)
                                  : const Color(0xFF9CA3AF),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 22),

                    _SmallLabel(
                      icon: Icons.star_border,
                      text: 'Interests',
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: interests.map((interest) {
                        final isSelected = selectedInterests.contains(interest);

                        return _ChipButton(
                          text: interest,
                          isSelected: isSelected,
                          isLuxury: isLuxury,
                          isNight: isNight,
                          onTap: () => toggleInterest(interest),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    _SmallLabel(
                      icon: Icons.groups_outlined,
                      text: 'Who are you traveling with?',
                      isLuxury: isLuxury,
                      isNight: isNight,
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: travelGroups.map((group) {
                        return _ChipButton(
                          text: group,
                          isSelected: selectedTravelGroup == group,
                          isLuxury: isLuxury,
                          isNight: isNight,
                          onTap: () {
                            setState(() {
                              selectedTravelGroup = group;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isLuxury || isNight ? const Color(0xFF0B1020) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLuxury ? 'Luxury AI Assistant' : 'AI Assistant',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLuxury
                          ? 'I will create a premium trip plan using luxury hotels, fine dining, private tours, and exclusive experiences.'
                          : 'I will create a trip plan based on your destination, budget, days, interests, and who you are traveling with.',
                      style: TextStyle(
                        color: isLuxury || isNight
                            ? const Color(0xFFB8B8D1)
                            : const Color(0xFF374151),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isLuxury || isNight ? const Color(0xFF0B1020) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart suggestions',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SuggestionChip(
                          text: isLuxury ? 'Private transfers' : 'Low walking',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                        _SuggestionChip(
                          text: isLuxury ? 'Fine dining' : 'Sunset spots',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                        _SuggestionChip(
                          text: isLuxury ? 'Luxury stays' : 'Photo-friendly',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                        _SuggestionChip(
                          text: isLuxury ? 'VIP experiences' : 'Hidden gems',
                          isLuxury: isLuxury,
                          isNight: isNight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final destination =
                        destinationController.text.trim().isEmpty
                            ? 'AI Generated Trip'
                            : destinationController.text.trim();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailsScreen(
                          title: isLuxury
                              ? '$destination Luxury Trip Plan'
                              : '$destination Trip Plan',
                          location: destination,
                          status: 'AI Generated',
                          duration:
                              '$tripDays ${tripDays == 1 ? 'day' : 'days'}',
                          budget: isLuxury
                              ? 'Luxury'
                              : selectedBudget == 'Custom'
                                  ? '\$${customBudgetController.text.trim().isEmpty ? 'Custom' : customBudgetController.text.trim()}'
                                  : selectedBudget,
                          style: isLuxury ? 'Luxury' : 'AI matched',
                          people: selectedTravelGroup,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    isLuxury ? 'Generate Luxury AI Plan' : 'Generate AI Suggestion',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor:
                        isLuxury ? const Color(0xFF111827) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLuxury;
  final bool isNight;

  const _SmallLabel({
    required this.icon,
    required this.text,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF6B7280);

    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLuxury;
  final bool isNight;

  const _ChipButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isLuxury
        ? const Color(0xFFE8C766)
        : isNight
            ? const Color(0xFFA855F7)
            : const Color(0xFF2563EB);
    final unselectedColor = isLuxury || isNight ? const Color(0xFF111827) : Colors.white;
    final selectedTextColor = isLuxury ? const Color(0xFF111827) : Colors.white;
    final unselectedTextColor = isLuxury
        ? const Color(0xFFB8B8B8)
        : isNight
            ? const Color(0xFFB8B8D1)
            : const Color(0xFF4B5563);
    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withOpacity(0.35)
        : isNight
            ? const Color(0xFFA855F7).withOpacity(0.35)
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? selectedColor : borderColor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final bool isLuxury;
  final bool isNight;

  const _SuggestionChip({
    required this.text,
    required this.isLuxury,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isLuxury || isNight ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLuxury
              ? const Color(0xFFE8C766).withOpacity(0.35)
              : isNight
                  ? const Color(0xFFA855F7).withOpacity(0.35)
                  : Colors.transparent,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isLuxury
              ? const Color(0xFFE8C766)
              : isNight
                  ? const Color(0xFFE879F9)
                  : const Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
