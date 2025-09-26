import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("About Water Monitor"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF1565C0),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Water Monitor",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Groundwater Monitoring & Analysis",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    "About This Application",
                    "Water Monitor is a comprehensive groundwater monitoring application designed to help users track, analyze, and understand groundwater levels across various monitoring stations throughout India. The application provides real-time data visualization, trend analysis, and comprehensive reporting tools for effective water resource management.",
                    Icons.info_outline,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    "Key Features",
                    "• Interactive Maps: Visualize monitoring stations across different regions\n\n• Real-time Data: Access up-to-date groundwater level measurements\n\n• Trend Analysis: Track water level changes over time with detailed charts\n\n• Multi-language Support: Available in 23+ Indian languages\n\n• Station Search: Find and filter monitoring stations by location\n\n• Historical Data: Access historical groundwater data for analysis",
                    Icons.star_outline,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    "Data Sources",
                    "The application integrates data from various government sources including:\n\n• Central Ground Water Board (CGWB)\n• India Water Resources Information System (India WRIS)\n• State Ground Water Departments\n• Ministry of Jal Shakti\n\nAll data is sourced from official government APIs and databases to ensure accuracy and reliability.",
                    Icons.source_outlined,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    "Purpose & Impact",
                    "This application aims to democratize access to groundwater information, enabling:\n\n• Farmers to make informed irrigation decisions\n• Researchers to analyze water trends\n• Policy makers to develop better water management strategies\n• Citizens to understand local water resources\n• Environmental organizations to monitor conservation efforts",
                    Icons.eco_outlined,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    "Technology Stack",
                    "Built using modern technologies for optimal performance:\n\n• Flutter for cross-platform mobile development\n• RESTful APIs for data integration\n• Interactive charts and visualization tools\n• Real-time data synchronization\n• Offline data caching capabilities",
                    Icons.code_outlined,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Smart India Hackathon Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Smart India Hackathon 2025",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "This application is developed as a project for Smart India Hackathon 2025, focusing on innovative solutions for water resource management and environmental sustainability.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            "SIH 2025 Project",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Footer
                  Center(
                    child: Text(
                      "Version 1.0.0\nDeveloped with ❤️ for India",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.4,
                      ),
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
  
  Widget _buildSectionCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
