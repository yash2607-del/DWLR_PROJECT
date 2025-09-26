import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home, do nothing
        break;
      case 1:
        Navigator.pushNamed(context, '/map');
        break;
      case 2:
        _showFAQsDialog();
        break;
      case 3:
        Navigator.pushNamed(context, '/stations');
        break;
      case 4:
        _showLanguageDialog();
        break;
    }
  }

  void _showFAQsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Frequently Asked Questions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFAQItem(
                  'What is groundwater monitoring?',
                  'Groundwater monitoring involves tracking water levels, quality, and flow in underground aquifers to ensure sustainable water resource management.',
                ),
                const SizedBox(height: 16),
                _buildFAQItem(
                  'How often is data updated?',
                  'Water level data is typically updated every 15 minutes from automated monitoring stations across the region.',
                ),
                const SizedBox(height: 16),
                _buildFAQItem(
                  'How to read water level trends?',
                  'Rising trends indicate water recharge, while declining trends may suggest over-extraction or drought conditions.',
                ),
                const SizedBox(height: 16),
                _buildFAQItem(
                  'What do the different station types mean?',
                  'Monitoring wells track water levels, Deep wells monitor deeper aquifers, and Urban wells focus on city water supplies.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    Navigator.pushNamed(context, '/language');
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Monitor Water",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Track Groundwater",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            "Real-time Data Monitoring",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Essentials Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Water Monitor Essentials",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _buildEssentialItem(
                          icon: Icons.map_outlined,
                          label: "View Maps",
                          onTap: () => Navigator.pushNamed(context, '/map'),
                        ),
                        _buildEssentialItem(
                          icon: Icons.location_on_outlined,
                          label: "Search Station Info",
                          onTap: () =>
                              Navigator.pushNamed(context, '/stations'),
                        ),
                        _buildEssentialItem(
                          icon: Icons.trending_up_outlined,
                          label: "Look Up Trends",
                          onTap: () => Navigator.pushNamed(context, '/charts'),
                        ),
                        
                        _buildEssentialItem(
                          icon: Icons.analytics_outlined,
                          label: "Analytics",
                          onTap: () =>
                              Navigator.pushNamed(context, '/analytics'),
                        ),
                        _buildEssentialItem(
                          icon: Icons.info_outline,
                          label: "About",
                          onTap: () => Navigator.pushNamed(context, '/about'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Additional Info Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Monitor your Water Resources",
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            "on Water Monitor. Get real-time",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            "data insights",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Color(0xFF1565C0),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ), // Closes SingleChildScrollView
      ), // Closes SafeArea
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildEssentialItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
