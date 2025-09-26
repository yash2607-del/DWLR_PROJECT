import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'nativeName': 'English', 'code': 'en'},
    {'name': 'Hindi', 'nativeName': 'हिंदी', 'code': 'hi'},
    {'name': 'Assamese', 'nativeName': 'অসমীয়া', 'code': 'as'},
    {'name': 'Bengali', 'nativeName': 'বাংলা', 'code': 'bn'},
    {'name': 'Bodo', 'nativeName': 'बर\'/बड़ो', 'code': 'brx'},
    {'name': 'Dogri', 'nativeName': 'डोगरी', 'code': 'doi'},
    {'name': 'Gujarati', 'nativeName': 'ગુજરાતી', 'code': 'gu'},
    {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ', 'code': 'kn'},
    {'name': 'Kashmiri', 'nativeName': 'کٲشُر', 'code': 'ks'},
    {'name': 'Konkani', 'nativeName': 'कोंकणी', 'code': 'gom'},
    {'name': 'Maithili', 'nativeName': 'मैथिली', 'code': 'mai'},
    {'name': 'Malayalam', 'nativeName': 'മലയാളം', 'code': 'ml'},
    {'name': 'Manipuri', 'nativeName': 'মেইতেই লোন্', 'code': 'mni'},
    {'name': 'Marathi', 'nativeName': 'मराठी', 'code': 'mr'},
    {'name': 'Nepali', 'nativeName': 'नेपाली', 'code': 'ne'},
    {'name': 'Odia', 'nativeName': 'ଓଡ଼ିଆ', 'code': 'or'},
    {'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ', 'code': 'pa'},
    {'name': 'Sanskrit', 'nativeName': 'संस्कृतम्', 'code': 'sa'},
    {'name': 'Santali', 'nativeName': 'ᱥᱟᱱᱛᱟᱲᱤ', 'code': 'sat'},
    {'name': 'Sindhi', 'nativeName': 'سنڌي', 'code': 'sd'},
    {'name': 'Tamil', 'nativeName': 'தமிழ்', 'code': 'ta'},
    {'name': 'Telugu', 'nativeName': 'తెలుగు', 'code': 'te'},
    {'name': 'Urdu', 'nativeName': 'اردو', 'code': 'ur'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Language'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
                const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose Your Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedLanguage',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Languages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['name'];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF1565C0) 
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          language['code']!.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      language['name']!,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      language['nativeName']!,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1565C0),
                            size: 24,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey,
                            size: 24,
                          ),
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language['name']!;
                      });
                      
                      // Show confirmation snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to ${language['name']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF1565C0),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      
                      // Navigate back after a short delay
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Bottom Note
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Note: Language changes will be applied to the entire app interface.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}