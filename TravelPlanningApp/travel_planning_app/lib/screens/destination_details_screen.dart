import 'package:flutter/material.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final String destination;
  final String country;
  final String selectedMode;

  const DestinationDetailsScreen({
    super.key,
    required this.destination,
    required this.country,
    this.selectedMode = 'Casual',
  });

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final isLuxury = widget.selectedMode == 'Luxury';
    final isNight = widget.selectedMode == 'Night';

    final backgroundColor = isLuxury
        ? const Color(0xFF030303)
        : isNight
            ? const Color(0xFF050818)
            : const Color(0xFFFDFDFD);

    final primaryTextColor = isLuxury || isNight
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

    final cardColor = isLuxury || isNight
        ? const Color(0xFF111827)
        : Colors.white;

    final borderColor = isLuxury
        ? const Color(0xFFE8C766).withOpacity(0.45)
        : isNight
            ? const Color(0xFFA855F7).withOpacity(0.35)
            : const Color(0xFFE5E7EB);

    final isBavarianTour = widget.destination == 'Private Bavarian Alps Tour';
    final isHalongPackage = widget.destination == 'Halong Bay Seaplane Tour';
    final isDubaiLuxuryPackage = widget.destination == 'Dubai Elite Yacht Escape';
    final isPrivateIslandPackage = widget.destination == 'Private Island Stay';
    final isJustCavalli = widget.destination == 'Just Cavalli Club';

    final isPackage = widget.destination == 'Rome First-Time Tour' ||
        widget.destination == 'Dubai City Highlights' ||
        widget.destination == 'Tokyo Discovery Tour' ||
        widget.destination == 'Halong Bay Seaplane Tour' ||
        widget.destination == 'Dubai Elite Yacht Escape' ||
        widget.destination == 'Private Island Stay';

    final imageAsset = isBavarianTour
        ? 'assets/images/privatebavariantour.jpg'
        : isHalongPackage
            ? 'assets/images/halongbay.jpg'
            : isDubaiLuxuryPackage
                ? 'assets/images/dubaiyacht.jpg'
                : isPrivateIslandPackage
                    ? 'assets/images/prvtislandstay.webp'
                    : isJustCavalli
                        ? 'assets/images/justcavalli.jpg'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'assets/images/rome.jpg'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'assets/images/dubai.png'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'assets/images/tokyo.webp'
                                    : 'assets/images/baligetaway.png';

    final title = isBavarianTour
        ? 'Private Bavarian Alps Tour'
        : isHalongPackage
            ? 'Halong Bay Seaplane Tour'
            : isDubaiLuxuryPackage
                ? 'Dubai Elite Yacht Escape'
                : isPrivateIslandPackage
                    ? 'Private Island Stay'
                    : isJustCavalli
                        ? 'Just Cavalli Club'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'Rome First-Time Tour'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'Dubai City Highlights'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'Tokyo Discovery Tour'
                                    : 'Island Escape Getaway';

    final location = isBavarianTour
        ? 'Bavaria, Germany'
        : isHalongPackage
            ? 'Halong Bay, Vietnam'
            : isDubaiLuxuryPackage
                ? 'Dubai, UAE'
                : isPrivateIslandPackage
                    ? 'Maldives'
                    : isJustCavalli
                        ? 'Dubai, UAE'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'Rome, Italy'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'Dubai, UAE'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'Tokyo, Japan'
                                    : 'Bali, Indonesia';

    final rating = isBavarianTour
        ? '4.9'
        : isHalongPackage
            ? '4.9'
            : isDubaiLuxuryPackage
                ? '4.8'
                : isPrivateIslandPackage
                    ? '4.9'
                    : isJustCavalli
                        ? '4.8'
                        : widget.destination == 'Rome First-Time Tour'
                            ? '4.7'
                            : widget.destination == 'Dubai City Highlights'
                                ? '4.6'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? '4.8'
                                    : '4.8';

    final description = isBavarianTour
        ? 'A private scenic luxury tour through the Bavarian Alps, designed for travelers who want mountain views, peaceful landscapes, premium comfort, and a curated countryside escape.'
        : isHalongPackage
            ? 'A premium seaplane tour over Halong Bay, designed for travelers who want breathtaking aerial views, limestone islands, emerald waters, and a luxury scenic experience from above.'
            : isDubaiLuxuryPackage
                ? 'A luxury Dubai escape combining a five-star hotel stay, private yacht experience, and fine dining. Designed for travelers who want premium comfort, skyline views, and a curated high-end city experience.'
                : isPrivateIslandPackage
                    ? 'A premium private island escape with an exclusive villa stay, private yacht transfer, and sunset fine dining. Designed for travelers who want privacy, ocean views, and a luxury tropical experience.'
                    : isJustCavalli
                        ? 'A luxury nightlife experience in Dubai with high-energy music, stylish interiors, premium vibes, and a glamorous club atmosphere for travelers who want an unforgettable night out.'
                        : widget.destination == 'Rome First-Time Tour'
                            ? 'A ready-made first-time tour package through Rome, designed for travelers who want to explore the citys most iconic landmarks, culture, history, and local atmosphere in one organized plan.'
                            : widget.destination == 'Dubai City Highlights'
                                ? 'A ready-made city package for discovering Dubais modern skyline, iconic attractions, shopping areas, and cultural highlights in one smooth travel plan.'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? 'A ready-made discovery package through Tokyo, combining modern city life, traditional culture, famous districts, local food, and unforgettable sightseeing stops.'
                                    : 'A peaceful beachside getaway designed for relaxing, enjoying ocean views, and spending time near the shore. This stay is perfect for travelers who want a calm escape with nature, beach walks, and a comfortable private place to unwind.';

    final price = isBavarianTour
        ? '\$1480'
        : isHalongPackage
            ? '\$980'
            : isDubaiLuxuryPackage
                ? '\$1850'
                : isPrivateIslandPackage
                    ? '\$3450'
                    : isJustCavalli
                        ? '\$\$\$'
                        : widget.destination == 'Rome First-Time Tour'
                            ? '\$320'
                            : widget.destination == 'Dubai City Highlights'
                                ? '\$290'
                                : widget.destination == 'Tokyo Discovery Tour'
                                    ? '\$340'
                                    : '\$680 / night';

    final buttonText = isPackage ? 'Add Package to Plan' : 'Add to Plan';

    final includedItems = widget.destination == 'Halong Bay Seaplane Tour'
        ? [
            {
              'imageAsset': 'assets/images/seaplane.jpg',
              'icon': Icons.flight_takeoff,
              'type': 'activity',
              'title': 'Scenic Seaplane Flight',
              'subtitle': 'Aerial views over limestone islands',
              'duration': '45m',
              'price': '\$420',
              'rating': '4.9',
            },
            {
              'imageAsset': 'assets/images/halongcruise.jpg',
              'icon': Icons.directions_boat_outlined,
              'type': 'activity',
              'title': 'Private Bay Cruise',
              'subtitle': 'Luxury cruise through emerald waters',
              'duration': '3h',
              'price': '\$380',
              'rating': '4.8',
            },
            {
              'imageAsset': 'assets/images/halongcave.jpg',
              'icon': Icons.landscape_outlined,
              'type': 'activity',
              'title': 'Cave & Island Stop',
              'subtitle': 'Hidden caves and island viewpoints',
              'duration': '2h',
              'price': '\$180',
              'rating': '4.7',
            },
          ]
        : widget.destination == 'Dubai Elite Yacht Escape'
            ? [
                {
                  'imageAsset': 'assets/images/5starhotel.webp',
                  'icon': Icons.hotel_outlined,
                  'type': 'hotel',
                  'title': 'Five-Star Hotel Stay',
                  'subtitle': 'Luxury suite with skyline views',
                  'duration': '1 night',
                  'price': '\$650',
                  'rating': '4.9',
                },
                {
                  'imageAsset': 'assets/images/privateyachttour.jpg',
                  'icon': Icons.directions_boat_outlined,
                  'type': 'activity',
                  'title': 'Private Yacht Tour',
                  'subtitle': 'Premium marina cruise with sea views',
                  'duration': '2h',
                  'price': '\$850',
                  'rating': '4.8',
                },
                {
                  'imageAsset': 'assets/images/finedining.webp',
                  'icon': Icons.restaurant_menu,
                  'type': 'restaurant',
                  'title': 'Fine Dining Experience',
                  'subtitle': 'Upscale dinner with curated menu',
                  'duration': '2h',
                  'price': '\$350',
                  'rating': '4.9',
                },
              ]
            : widget.destination == 'Private Island Stay'
                ? [
                    {
                      'imageAsset': 'assets/images/privatevilla.jpg',
                      'icon': Icons.villa_outlined,
                      'type': 'hotel',
                      'title': 'Private Island Villa',
                      'subtitle': 'Exclusive villa with ocean views',
                      'duration': '1 night',
                      'price': '\$1800',
                      'rating': '4.9',
                    },
                    {
                      'imageAsset': 'assets/images/yachttransfer.jpg',
                      'icon': Icons.directions_boat_outlined,
                      'type': 'activity',
                      'title': 'Yacht Transfer',
                      'subtitle': 'Private yacht arrival experience',
                      'duration': '1h',
                      'price': '\$950',
                      'rating': '4.8',
                    },
                    {
                      'imageAsset': 'assets/images/sunsetdining.webp',
                      'icon': Icons.restaurant_menu,
                      'type': 'restaurant',
                      'title': 'Sunset Fine Dining',
                      'subtitle': 'Beachfront dinner with curated menu',
                      'duration': '2h',
                      'price': '\$700',
                      'rating': '4.9',
                    },
                  ]
                : widget.destination == 'Rome First-Time Tour'
                    ? [
                        {
                          'imageAsset': 'assets/images/colosseum.webp',
                          'icon': Icons.account_balance_outlined,
                          'type': 'activity',
                          'title': 'Colosseum Tour',
                          'subtitle': 'Ancient Rome guided landmark visit',
                          'tags': ['Culture', 'History', 'Landmark'],
                          'duration': '2h',
                          'price': '\$90',
                          'rating': '4.8',
                        },
                        {
                          'imageAsset': 'assets/images/vatican.webp',
                          'icon': Icons.church_outlined,
                          'type': 'activity',
                          'title': 'Vatican Visit',
                          'subtitle': 'Art, history, museums, and culture',
                          'tags': ['Art', 'Culture', 'Museum'],
                          'duration': '2.5h',
                          'price': '\$120',
                          'rating': '4.7',
                        },
                        {
                          'imageAsset': 'assets/images/pizza.jpg',
                          'icon': Icons.restaurant_outlined,
                          'type': 'restaurant',
                          'title': 'Roman Food Walk',
                          'subtitle': 'Pasta, pizza, gelato, and local bites',
                          'tags': ['Food', 'Local', 'Walking'],
                          'duration': '1.5h',
                          'price': '\$110',
                          'rating': '4.9',
                        },
                      ]
                    : widget.destination == 'Dubai City Highlights'
                        ? [
                            {
                              'imageAsset': 'assets/images/burjkhalifa.jpg',
                              'icon': Icons.location_city_outlined,
                              'type': 'activity',
                              'title': 'Burj Khalifa Visit',
                              'subtitle': 'City skyline views from the top',
                              'tags': ['Views', 'Landmark', 'Luxury'],
                              'duration': '1.5h',
                              'price': '\$120',
                              'rating': '4.8',
                            },
                            {
                              'imageAsset': 'assets/images/dubaimall.jpg',
                              'icon': Icons.shopping_bag_outlined,
                              'type': 'activity',
                              'title': 'Dubai Mall Stop',
                              'subtitle': 'Shopping, cafes, and attractions',
                              'tags': ['Shopping', 'Modern', 'Indoor'],
                              'duration': '2h',
                              'price': '\$70',
                              'rating': '4.6',
                            },
                            {
                              'imageAsset': 'assets/images/dubaimarina.webp',
                              'icon': Icons.waves_outlined,
                              'type': 'activity',
                              'title': 'Marina Walk',
                              'subtitle': 'Waterfront walk with skyline views',
                              'tags': ['Waterfront', 'Views', 'Relax'],
                              'duration': '1h',
                              'price': '\$100',
                              'rating': '4.7',
                            },
                          ]
                        : widget.destination == 'Tokyo Discovery Tour'
                            ? [
                                {
                                  'imageAsset': 'assets/images/asakusatemple.jpg',
                                  'icon': Icons.temple_buddhist_outlined,
                                  'type': 'activity',
                                  'title': 'Asakusa Temple Visit',
                                  'subtitle': 'Traditional culture and historic streets',
                                  'tags': ['Culture', 'Temple', 'History'],
                                  'duration': '2h',
                                  'price': '\$95',
                                  'rating': '4.8',
                                },
                                {
                                  'imageAsset': 'assets/images/shibuyacrossing.jpg',
                                  'icon': Icons.train_outlined,
                                  'type': 'activity',
                                  'title': 'Shibuya Crossing',
                                  'subtitle': 'Famous city lights and urban energy',
                                  'tags': ['City', 'Modern', 'Photo'],
                                  'duration': '1h',
                                  'price': '\$80',
                                  'rating': '4.7',
                                },
                                {
                                  'imageAsset': 'assets/images/japanesefood.jpg',
                                  'icon': Icons.ramen_dining_outlined,
                                  'type': 'restaurant',
                                  'title': 'Local Food Stop',
                                  'subtitle': 'Ramen, sushi, and street snacks',
                                  'tags': ['Food', 'Local', 'Taste'],
                                  'duration': '1.5h',
                                  'price': '\$165',
                                  'rating': '4.9',
                                },
                              ]
                            : [];

    return Scaffold(
      backgroundColor: backgroundColor,

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to plan'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isLuxury ? const Color(0xFF111827) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : primaryTextColor,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  imageAsset,
                  width: double.infinity,
                  height: 320,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: secondaryTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                  const Icon(Icons.star_half, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    rating,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                description,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Price: $price',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              if (isPackage) ...[
                const SizedBox(height: 18),
                Text(
                  'Included in this package',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...includedItems.map((item) {
                  return _PackageIncludedCard(
                    imageAsset: item['imageAsset'] as String?,
                    icon: item['icon'] as IconData,
                    type: item['type'] as String,
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    duration: item['duration'] as String,
                    price: item['price'] as String,
                    rating: item['rating'] as String,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: accentColor,
                    isLuxury: isLuxury,
                  );
                }),
              ],

              if (!isPackage || isBavarianTour || isJustCavalli)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: secondaryTextColor,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBavarianTour
                          ? '8 hours'
                          : isJustCavalli
                              ? '5 hours'
                              : '24 hours',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }
}

class _PackageIncludedCard extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String type;
  final String title;
  final String subtitle;
  final String duration;
  final String price;
  final String rating;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final bool isLuxury;

  const _PackageIncludedCard({
    this.imageAsset,
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
    required this.rating,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.isLuxury,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 112,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isLuxury
                  ? const Color(0xFFE8C766).withOpacity(0.14)
                  : const Color(0xFFEFF6FF),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
              image: imageAsset != null
                  ? DecorationImage(
                      image: AssetImage(imageAsset!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageAsset == null
                ? Center(
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 44,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
