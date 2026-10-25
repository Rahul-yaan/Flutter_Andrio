import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _prefKey = 'app_language';
  
  /// Supported language codes: 'en' for English, 'hi' for Hindi
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  static String get currentLanguage => languageNotifier.value;
  static bool get isHindi => languageNotifier.value == 'hi';

  /// Initialize saved language preference on app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey) ?? 'en';
      languageNotifier.value = savedLang;
    } catch (e) {
      debugPrint('LanguageService init error: $e');
    }
  }

  /// Change active language and persist to SharedPreferences
  static Future<void> setLanguage(String langCode) async {
    if (langCode != 'en' && langCode != 'hi') return;
    languageNotifier.value = langCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Translation function: If Hindi is active, returns Hindi translated string if available
  static String tr(String key) {
    if (!isHindi) return key;
    return _translations[key] ?? key;
  }

  /// Show modern, interactive Language Selection Bottom Sheet / Modal
  static void showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (context, activeLang, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.translate_rounded, color: Color(0xFFC0392B), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Select Language / भाषा चुनें',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred display language',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // Option 1: English
                  _buildLanguageOption(
                    title: 'English',
                    subtitle: 'Default language',
                    flag: '🇬🇧',
                    isSelected: activeLang == 'en',
                    onTap: () {
                      setLanguage('en');
                      Navigator.pop(ctx);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Option 2: Hindi (हिंदी)
                  _buildLanguageOption(
                    title: 'हिंदी (Hindi)',
                    subtitle: 'सभी विवरण हिंदी में देखें (भुगतान छोड़कर)',
                    flag: '🇮🇳',
                    isSelected: activeLang == 'hi',
                    onTap: () {
                      setLanguage('hi');
                      Navigator.pop(ctx);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F0) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFC0392B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFC0392B) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF8B1E0F) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFC0392B), size: 22)
            else
              const Icon(Icons.radio_button_off_rounded, color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }

  /// English -> Hindi translation dictionary
  static final Map<String, String> _translations = {
    // Navigation / Tabs
    'Home': 'होम',
    'My Bookings': 'मेरी बुकिंग्स',
    'Scan': 'स्कैन',
    'Scan QR': 'स्कैन क्यूआर',
    'Bookings': 'बुकिंग्स',
    'Profile': 'प्रोफ़ाइल',
    'Notifications': 'सूचनाएं',
    'Notifications & Offers': 'सूचनाएं एवं ऑफ़र',
    'Language': 'भाषा',
    'Language / भाषा': 'भाषा (Language)',
    'Select Language': 'भाषा चुनें',

    // Home Page Header & Search
    'Find Hotels': 'होटल खोजें',
    'Find & Book Highway Stay': 'हाईवे स्टे और पार्किंग खोजें',
    'Search hotels on your route': 'अपने मार्ग पर सुरक्षित होटल खोजें',
    'Pickup location': 'प्रस्थान शहर (From)',
    'Origin city': 'प्रस्थान शहर (From)',
    'Starting city': 'प्रस्थान शहर (From)',
    'Destination city': 'गंतव्य शहर (To)',
    'Search Hotels': 'होटल खोजें',
    'Searching...': 'खोज रहे हैं...',
    'Enter both From and To locations': 'कृपया दोनों स्थान (From और To) दर्ज करें',
    'Please select locations from suggestions': 'कृपया सूची से स्थान चुनें',
    'Amenities & Services': 'सुविधाएं एवं सेवाएं',
    'Nearby Highway Facilities': 'हाईवे सुविधाएं',
    'Truck Parking': 'ट्रक पार्किंग',
    'Food / Dhaba': 'भोजन / ढाबा',
    'Restroom': 'शौचालय',
    'Security': '24/7 सुरक्षा',
    'Drinking Water': 'पीने का पानी',
    'Mechanic Support': 'मैकेनिक सहायता',
    'Special Offers & Announcements': 'विशेष ऑफ़र एवं घोषणाएं',
    'Got Query? Reach out us at': 'कोई प्रश्न है? हमसे संपर्क करें',
    'CHAT WITH US': 'व्हाट्सएप चैट करें',
    'Call Us': 'कॉल करें',
    'Contact Support': 'सपोर्ट से संपर्क करें',
    'Spot Booking with QR': 'क्यूआर द्वारा स्पॉट बुकिंग',
    'Scan hotel reception QR code for instant room booking': 'त्वरित रूम बुकिंग के लिए होटल रिसेप्शन क्यूआर कोड स्कैन करें',
    'ADMIN OFFER': 'ऑफ़र',
    'ADMIN NEWS': 'समाचार',
    'HOTEL & SPOT OFFERS': 'होटल एवं स्पॉट ऑफ़र',
    'Exclusive Highway Deals': 'विशेष हाईवे डील्स',
    'Book verified highway partner hotels with instant spot QR check-in & best room rates.': 'सत्यापित हाईवे पार्टनर होटलों पर तुरंत क्यूआर चेक-इन और सर्वोत्तम रूम दरें पाएं।',
    'Explore Hotels & Book Now': 'होटल देखें और अभी बुक करें',
    'COUPON CODE': 'कूपन कोड',
    'Copy': 'कॉपी करें',
    'HOTEL OFFER': 'होटल ऑफ़र',

    // Search Results Page
    'Search Results': 'खोज परिणाम',
    'Hotels Found': 'होटल उपलब्ध हैं',
    'hotels found on route': 'होटल मार्ग पर उपलब्ध हैं',
    'No hotels found on this route': 'इस मार्ग पर कोई होटल नहीं मिला',
    'Per Night': 'प्रति रात',
    'Slots Available': 'पार्किंग स्लॉट उपलब्ध',
    'View Details': 'विवरण देखें',
    'Book Now': 'अभी बुक करें',
    'Book': 'बुक करें',
    'Distance': 'दूरी',
    'Rating': 'रेटिंग',
    'Filters': 'फ़िल्टर',
    'All Amenities': 'सभी सुविधाएं',
    'Lowest Price': 'न्यूनतम मूल्य',
    'Highest Rated': 'उच्चतम रेटिंग',
    'Sort': 'क्रमबद्ध',
    'Reverse Route': 'उल्टा मार्ग',
    'Price ↑': 'मूल्य: कम से ज्यादा',
    'Price ↓': 'मूल्य: ज्यादा से कम',
    'Sort Hotels': 'होटल क्रमबद्ध करें',
    'Start to Destination (Route Order)': 'प्रस्थान से गंतव्य (मार्ग क्रम)',
    'Destination to Start (Reverse Route)': 'गंतव्य से प्रस्थान (उल्टा मार्ग)',
    'Price: Low to High': 'मूल्य: कम से अधिक',
    'Price: High to Low': 'मूल्य: अधिक से कम',
    'Rating: High to Low': 'रेटिंग: उच्चतम रेटिंग पहले',
    'Budget friendly options first': 'किफायती विकल्प पहले',
    'Premium hotels first': 'प्रीमियम होटल पहले',
    'Best customer rated hotels': 'सर्वश्रेष्ठ रेटिंग वाले होटल',
    'List': 'सूची',
    'Map': 'मैप',
    'Fastest Route': 'सबसे तेज़ मार्ग',

    // Hotel Detail Page
    'Hotel Details': 'होटल विवरण',
    'About Hotel': 'होटल के बारे में',
    'About': 'होटल के बारे में',
    'Amenities': 'उपलब्ध सुविधाएं',
    'Location & Address': 'स्थान एवं पता',
    'Reviews & Ratings': 'समीक्षाएं एवं रेटिंग',
    'Available Parking Slots': 'उपलब्ध पार्किंग स्लॉट',
    'Per Night Rate': 'प्रति रात दर',
    'Price/Night': 'प्रति रात मूल्य',
    'Available Slots': 'उपलब्ध स्लॉट',
    'Book Stay & Parking': 'स्टे एवं पार्किंग बुक करें',
    'No reviews yet': 'अभी तक कोई समीक्षा नहीं है',
    'No reviews yet.': 'अभी तक कोई समीक्षा नहीं है।',
    'Get Directions': 'दिशा-निर्देश प्राप्त करें',
    'Call Hotel': 'होटल को कॉल करें',
    'Total Rooms': 'कुल कमरे',
    'Address': 'होटल का पता',
    'Write a Review': 'समीक्षा लिखें',
    'Submit Review': 'समीक्षा सबमिट करें',
    'Location & Route': 'स्थान एवं मार्ग',
    'Reviews': 'समीक्षाएं',
    'Sold Out': 'सभी स्लॉट भरे हैं',
    'Parking': 'ट्रक पार्किंग',
    'Food': 'भोजन',
    'Water': 'पीने का पानी',
    'Mechanic': 'मैकेनिक सहायता',

    // Booking Details / Truck Info Form (in booking_page.dart)
    'Confirm Booking': 'बुकिंग विवरण',
    'Logistics & Truck Info': 'लॉजिस्टिक्स एवं ट्रक विवरण',
    'Booking Date': 'बुकिंग की तारीख',
    'Truck Type': 'ट्रक का प्रकार',
    'Select Your Truck Type': 'ट्रक का प्रकार चुनें',
    'Truck No': 'ट्रक नंबर (गाड़ी नंबर)',
    'Truck Number': 'ट्रक नंबर (गाड़ी नंबर)',
    'Logistics Name': 'लॉजिस्टिक्स / ट्रांसपोर्ट नाम',
    'Logistics Contact Number': 'ड्राइवर / ट्रांसपोर्ट संपर्क नंबर',
    'Logistics Contact': 'ड्राइवर संपर्क नंबर',
    'Logistics Number': 'ड्राइवर / ट्रांसपोर्ट मोबाइल नंबर',
    'Enter vehicle registration number': 'गाड़ी का नंबर दर्ज करें (उदा. GJ16AB7888)',
    'Enter Truck Number (e.g. GJ16AB7888)': 'गाड़ी का नंबर दर्ज करें (उदा. GJ16AB7888)',
    'Enter logistics or transport company': 'ट्रांसपोर्ट कंपनी का नाम दर्ज करें',
    'Enter Logistics Name': 'ट्रांसपोर्ट का नाम दर्ज करें',
    'Enter driver mobile number': 'ड्राइवर का 10-अंकों का मोबाइल नंबर दर्ज करें',
    'Enter Logistics Number': '10-अंकों का मोबाइल नंबर दर्ज करें',
    'Offers & Coupons': 'ऑफ़र एवं कूपन कोड',
    'Apply Offer or Coupon Code': 'ऑफ़र या कूपन कोड लागू करें',
    'Enter promo code': 'कूपन कोड दर्ज करें',
    'Enter Promo Code (e.g. YAANSPOT)': 'प्रोमो कोड दर्ज करें (उदा. YAANSPOT)',
    'Apply': 'लागू करें',
    'APPLY': 'लागू करें',
    'Applied': 'लागू है',
    'Remove': 'हटाएं',
    'REMOVE': 'हटाएं',
    'View Offers': 'ऑफ़र देखें',
    'Hide Offers': 'ऑफ़र छिपाएं',
    'Special Offer': 'विशेष ऑफ़र',
    'Valid coupon applied successfully!': 'कूपन सफलतापूर्वक लागू हुआ!',
    'Invalid promo code': 'अमान्य कूपन कोड',
    'Please enter vehicle registration number': 'कृपया गाड़ी का नंबर दर्ज करें',
    'Please enter valid 10-digit mobile number': 'कृपया सही 10-अंकों का मोबाइल नंबर दर्ज करें',
    'View on Map': 'मैप पर देखें',
    'Booking Successful!': 'बुकिंग सफल हुई!',
    'Back to Home': 'होम पेज पर जाएं',
    'I agree to the Terms & Conditions and Cancellation Policy of Yaan.': 'मैं यान (Yaan) के नियम व शर्तों और रद्दीकरण नीति से सहमत हूँ।',

    // NOTE: PAYMENT DETAILS ARE DELIBERATELY EXCLUDED FROM TRANSLATION AS EXPLICITLY REQUESTED

    // My Bookings Page
    'Upcoming': 'आगामी',
    'Completed': 'पूर्ण',
    'Cancelled': 'रद्द',
    'Booking ID': 'बुकिंग आईडी',
    'Check-in': 'चेक-इन',
    'Check-out': 'चेक-आउट',
    'Show QR Code': 'क्यूआर कोड दिखाएं',
    'Show QR Pass': 'क्यूआर पास दिखाएं',
    'Check-In Pass': 'चेक-इन पास',
    'Show this QR code at hotel reception to confirm check-in': 'चेक-इन सत्यापित करने के लिए होटल रिसेप्शन पर यह क्यूआर दिखाएं',
    'Cancel Booking': 'बुकिंग रद्द करें',
    'Are you sure you want to cancel this booking?': 'क्या आप वाकई यह बुकिंग रद्द करना चाहते हैं?',
    'Yes, Cancel': 'हाँ, रद्द करें',
    'No': 'नहीं',
    'No bookings found': 'कोई बुकिंग नहीं मिली',
    'No bookings yet': 'अभी तक कोई बुकिंग नहीं है',
    'Status': 'स्थिति',
    'Confirmed': 'स्वीकृत (Confirmed)',
    'Pending': 'लंबित (Pending)',
    'CONFIRMED': 'स्वीकृत (Confirmed)',
    'PENDING': 'लंबित (Pending)',
    'CANCELLED': 'रद्द (Cancelled)',
    'COMPLETED': 'पूर्ण (Completed)',
    'View Hotel on Map': 'मैप पर होटल देखें',
    'Booking cancelled successfully': 'बुकिंग सफलतापूर्वक रद्द कर दी गई',

    // Profile Page
    'Other Information': 'अन्य जानकारी',
    'Terms & Conditions': 'नियम एवं शर्तें',
    'About Us': 'हमारे बारे में',
    'Privacy Policy': 'गोपनीयता नीति',
    'Contact Us': 'संपर्क करें',
    'Share App': 'ऐप शेयर करें',
    'Share Yaan App': 'ऐप शेयर करें',
    'Rate Us': 'रेटिंग दें',
    'Rate Yaan App': 'ऐप को रेटिंग दें',
    'LOG OUT': 'लॉग आउट',
    'Log Out': 'लॉग आउट',
    'Are you sure you want to log out?': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
    'Cancel': 'रद्द करें',
    'CANCEL': 'रद्द करें',
    'SUBMIT': 'सबमिट करें',
    'CLOSE': 'बंद करें',
    'COPY LINK': 'लिंक कॉपी करें',
    'Edit Profile': 'प्रोफ़ाइल संपादित करें',
    'Save': 'सहेजें',
    'Name': 'नाम',
    'Email': 'ईमेल',
    'Phone': 'फोन नंबर',

    // QR Scanner & Notifications
    'Scan QR Code': 'क्यूआर कोड स्कैन करें',
    'Align QR code within the frame to verify check-in': 'चेक-इन सत्यापन के लिए फ्रेम में क्यूआर कोड रखें',
    'Flash': 'टॉर्च',
    'Switch Camera': 'कैमरा बदलें',
    'No notifications available': 'कोई नई सूचना नहीं है',
    'Mark all as read': 'सभी को पढ़ा हुआ चिह्नित करें',
  };
}

/// Helper extension on String to allow quick `'Text'.tr()` syntax
extension TranslationExtension on String {
  String tr() => LanguageService.tr(this);
}