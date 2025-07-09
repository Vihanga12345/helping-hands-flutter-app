import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling offline translations between English, Sinhala, and Tamil
class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  // Language codes
  static const String englishCode = 'en';
  static const String sinhalaCode = 'si';
  static const String tamilCode = 'ta';

  String _currentLanguage = englishCode;
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  // Offline translations data
  static const Map<String, Map<String, String>> _offlineTranslations = {
    sinhalaCode: {
      // Common UI elements
      'Home': 'මුල් පිටුව',
      'Profile': 'පැතිකඩ',
      'Menu': 'මෙනුව',
      'Settings': 'සැකසීම්',
      'Notifications': 'දැනුම්දීම්',
      'Calendar': 'දින දර්ශනය',
      'Search': 'සොයන්න',
      'Back': 'ආපසු',
      'Next': 'ඊළඟ',
      'Done': 'සම්පූර්ණයි',
      'Save': 'සුරකින්න',
      'Cancel': 'අවලංගු කරන්න',
      'Delete': 'මකන්න',
      'Edit': 'සංස්කරණය කරන්න',
      'Submit': 'ඉදිරිපත් කරන්න',
      'Confirm': 'සනාථ කරන්න',
      'Close': 'වසන්න',
      'OK': 'හරි',
      'Yes': 'ඔව්',
      'No': 'නැත',
      'Loading...': 'පූර්ණ කරමින්...',
      'Error': 'දෝෂයක්',
      'Success': 'සාර්ථකයි',
      'Warning': 'අවවාදය',
      'Information': 'තොරතුරු',
      'Language': 'භාෂාව',
      'English': 'ඉංග්‍රීසි',
      'Sinhala': 'සිංහල',
      'Tamil': 'දෙමළ',
      'Switch Language': 'භාෂාව මාරු කරන්න',
      'Activity': 'ක්‍රියාකාරකම්',
      'Request': 'ඉල්ලීම',
      'Job Request': 'රැකියා ඉල්ලීම',
      'Job Details': 'රැකියා විස්තර',
      'Helper': 'උදව්කරුවා',
      'Status': 'තත්ත්වය',
      'Pending': 'අපේක්ෂිතයි',
      'Ongoing': 'ක්‍රියාත්මක',
      'Completed': 'සම්පූර්ණයි',
      'Accepted': 'පිළිගත්',
      'Rejected': 'ප්‍රතික්ෂේප කළා',
      'Available': 'ලබා ගත හැකිය',
      'Busy': 'කාර්යබහුල',
      'Offline': 'නොබැඳි',
      'Online': 'සම්බන්ධිත',
      'Search for helpers': 'උදව්කරුවන් සොයන්න',
      'No helpers found': 'උදව්කරුවන් හමු නොවිණි',
      'View Profile': 'පැතිකඩ බලන්න',
      'Rate Helper': 'උදව්කරුවාට ශ්‍රේණියක් දෙන්න',
      'Submit Review': 'සමාලෝචනයක් ඉදිරිපත් කරන්න',
      'No notifications': 'දැනුම්දීම් නැත',
      'Mark as read': 'කියවූ ලෙස සලකුණු කරන්න',
      'Clear all': 'සියල්ල ඉවත් කරන්න',
      'Today': 'අද',
      'Yesterday': 'ඊයේ',
      'This week': 'මෙම සතිය',
      'This month': 'මෙම මාසය',
      'Welcome': 'සාදරයෙන් පිළිගනිමු',
      'Welcome!': 'සාදරයෙන් පිළිගනිමු!',
      'Good morning': 'සුභ උදෑසනක්',
      'Good afternoon': 'සුභ දහවලක්',
      'Good evening': 'සුභ සවසක්',
      'Payment': 'ගෙවීම',
      'Payments': 'ගෙවීම්',
      'Amount': 'මුදල',
      'Pay Now': 'දැන් ගෙවන්න',
      'Payment Successful': 'ගෙවීම සාර්ථකයි',
      'Payment Failed': 'ගෙවීම අසාර්ථකයි',
      'About Us': 'අප ගැන',
      'Help & Support': 'උදව් සහ සහාය',
      'Contact Us': 'අපව සම්බන්ධ කරන්න',
      'Rate': 'ශ්‍රේණිගත කරන්න',
      'Review': 'සමාලෝචනය',
      'My Jobs': 'මගේ රැකියා',
      'Job History': 'රැකියා ඉතිහාසය',
      'Logout': 'ඉවත් වන්න',
      'Account': 'ගිණුම',
      'Helpee Account': 'උදව් ඉල්ලන්නාගේ ගිණුම',
      'Dark Mode': 'අඳුරු තේමාව',
      'Name': 'නම',
      'Email': 'විද්‍යුත් තැපෑල',
      'Phone': 'දුරකථනය',
      'Address': 'ලිපිනය',
      'Date': 'දිනය',
      'Time': 'වේලාව',
      'Location': 'ස්ථානය',
      'Description': 'විස්තරය',
      'Rating': 'ශ්‍රේණිගත කිරීම',
      'Reviews': 'සමාලෝචන',
      'Contact': 'සම්බන්ධතා',
      'Message': 'පණිවිඩය',
      'Send Message': 'පණිවිඩය යවන්න',
      'Call': 'ඇමතුම',
      'Distance': 'දුර',
      'Nearby': 'ආසන්නයේ',
      'Price': 'මිල',
      'Duration': 'කාලසීමාව',
      'No jobs available': 'වැඩ නැත',
      'No jobs for': 'වැඩ නැත',
      'No jobs scheduled for this day': 'මෙම දිනය සඳහා වැඩ නැත',
      'Pending Jobs': 'අපේක්ෂිත රැකියා',
      'No data available': 'දත්ත නැත',
      'Try again': 'නැවත උත්සාහ කරන්න',
      'Refresh': 'නැවුම් කරන්න',
      'Something went wrong': 'කුමක් හෝ වැරදුණි',
      'Please try again later': 'කරුණාකර පසුව නැවත උත්සාහ කරන්න',
      'Internet connection required': 'අන්තර්ජාල සම්බන්ධතාවය අවශ්‍යයි',
      'Check your connection': 'ඔබේ සම්බන්ධතාවය පරීක්ෂා කරන්න',
      'Update Available': 'යාවත්කාලීන කිරීමක් ඇත',
      'Update Now': 'දැන් යාවත්කාලීන කරන්න',
      'Skip': 'මඟ හරින්න',
      'Help': 'උදව්',
      'Support': 'සහාය',
      'January': 'ජනවාරි',
      'February': 'පෙබරවාරි',
      'March': 'මාර්තු',
      'April': 'අප්‍රේල්',
      'May': 'මැයි',
      'June': 'ජූනි',
      'July': 'ජූලි',
      'August': 'අගෝස්තු',
      'September': 'සැප්තැම්බර්',
      'October': 'ඔක්තෝබර්',
      'November': 'නොවැම්බර්',
      'December': 'දෙසැම්බර්',
      'th': 'වන',
      'st': 'වන',
      'nd': 'වන',
      'rd': 'වන',
      'Job Date': 'රැකියා දිනය',
      'Job Time': 'රැකියා වේලාව',
      'Job Location': 'රැකියා ස්ථානය',
      'Job Type': 'රැකියා වර්ගය',
      'Job Title': 'රැකියා මාතෘකාව',
      'Job Additional Details': 'රැකියා අමතර විස්තර',
      'Job Description': 'රැකියා විස්තරය',
      'Job Status': 'රැකියා තත්ත්වය',
      'Request Pending': 'ඉල්ලීම අපේක්ෂිතයි',
      'Waiting for Helper': 'උදව්කරුවා සඳහා රැඳී සිටිමින්',
      'Request Created': 'ඉල්ලීම නිර්මාණය කරන ලදී',
      'Priority': 'ප්‍රමුඛතාවය',
      'Visibility': 'දෘශ්‍යතාව',
      'Public': 'පොදු',
      'Private': 'පෞද්ගලික',
      'Estimated Response': 'ගණන් බලන ලද ප්‍රතිචාරය',
      'Within 2 hours': 'පැය 2 ක් ඇතුළත',
      'Available Actions': 'ලබා ගත හැකි ක්‍රියා',
      'Edit Request': 'ඉල්ලීම සංස්කරණය කරන්න',
      'Cancel Request': 'ඉල්ලීම අවලංගු කරන්න',
      'Keep Request': 'ඉල්ලීම තබා ගන්න',
      'Edit Profile': 'පැතිකඩ සංස්කරණය කරන්න',
      'Push Notifications': 'තල්ලු දැනුම්දීම්',
      'Save Changes': 'වෙනස්කම් සුරකින්න',
      'Search Helpers': 'උදව්කරුවන් සොයන්න',
      'All': 'සියල්ල',
      'Available Now': 'දැන් ලබා ගත හැකිය',
      'Top Rated': 'ඉහළ ශ්‍රේණිගත',
      'Quick Actions': 'ඉක්මන් ක්‍රියා',
      'Request Help': 'උදව් ඉල්ලන්න',
      'Find Helpers': 'උදව්කරුවන් සොයන්න',
      'Need Help?': 'උදව් අවශ්‍ය ද?',
      'Get started by creating your first job request or browse available helpers in your area.':
          'ඔබේ පළමු කාර්ය ඉල්ලීම සාදන්න හෝ ඔබේ ප්‍රදේශයේ ඇති උදව්කරුවන් බලන්න.',
      'Create Job Request': 'කාර්ය ඉල්ලීම සාදන්න',
      'How can we help you today?': 'අද අපට ඔබට කෙසේ උදව් කළ හැකිද?',
      'Select Location': 'ස්ථානය තෝරන්න',
      'Selected Address': 'තෝරාගත් ලිපිනය',
      'Enter address manually': 'ලිපිනය හස්තීයව ඇතුළත් කරන්න',
      'Interactive Map': 'අන්තර්ක්‍රියාකාරී සිතියම',
      'Getting Location...': 'ස්ථානය ලබා ගනිමින්...',
      'Tap on the map to select a location':
          'ස්ථානයක් තෝරා ගැනීමට සිතියම මත ටැප් කරන්න',
      'Selected Location': 'තෝරාගත් ස්ථානය',
      'Confirm Location': 'ස්ථානය තහවුරු කරන්න',
      'Select Current Address': 'වත්මන් ලිපිනය තෝරන්න',
      'Job request created successfully!': 'කාර්ය ඉල්ලීම සාර්ථකව නිර්මාණය විය!',
      'Job request updated successfully!':
          'කාර්ය ඉල්ලීම සාර්ථකව යාවත්කාලීන විය!',
      'Profile updated successfully!': 'පැතිකඩ සාර්ථකව යාවත්කාලීන විය!',
      'Login successful!': 'ඇතුල් වීම සාර්ථකයි!',
      'Registration successful!': 'ලියාපදිංචි කිරීම සාර්ථකයි!',
      'We\'re finding the best helpers for you. You\'ll be notified once someone accepts.':
          'අපි ඔබට හොඳම උදව්කරුවන් සොයමින් සිටිමු. කවුරුහරි පිළිගත් කළ විට ඔබට දැනුම් දෙනු ඇත.',
    },
    tamilCode: {
      // Common UI elements
      'Home': 'முகப்பு',
      'Profile': 'சுயவிவரம்',
      'Menu': 'பட்டியல்',
      'Settings': 'அமைப்புகள்',
      'Notifications': 'அறிவிப்புகள்',
      'Calendar': 'நாட்காட்டி',
      'Search': 'தேடல்',
      'Back': 'பின்',
      'Next': 'அடுத்து',
      'Done': 'முடிந்தது',
      'Save': 'சேமிக்கவும்',
      'Cancel': 'ரத்து செய்யவும்',
      'Delete': 'நீக்கவும்',
      'Edit': 'திருத்து',
      'Submit': 'சமர்ப்பிக்கவும்',
      'Confirm': 'உறுதிப்படுத்து',
      'Close': 'மூடு',
      'OK': 'சரி',
      'Yes': 'ஆம்',
      'No': 'இல்லை',
      'Loading...': 'ஏற்றுகிறது...',
      'Error': 'பிழை',
      'Success': 'வெற்றி',
      'Warning': 'எச்சரிக்கை',
      'Information': 'தகவல்',
      'Language': 'மொழி',
      'English': 'ஆங்கிலம்',
      'Sinhala': 'சிங்களம்',
      'Tamil': 'தமிழ்',
      'Switch Language': 'மொழி மாற்றவும்',
      'Activity': 'செயல்பாடு',
      'Request': 'கோரிக்கை',
      'Job Request': 'வேலை கோரிக்கை',
      'Job Details': 'வேலை விவரங்கள்',
      'Helper': 'உதவியாளர்',
      'Status': 'நிலை',
      'Pending': 'நிலுவையில்',
      'Ongoing': 'நடைபெறுகிறது',
      'Completed': 'முடிந்தது',
      'Accepted': 'ஏற்றுக்கொள்ளப்பட்டது',
      'Rejected': 'நிராகரிக்கப்பட்டது',
      'Available': 'கிடைக்கிறது',
      'Busy': 'பிஸி',
      'Offline': 'ஆஃப்லைன்',
      'Online': 'ஆன்லைன்',
      'Search for helpers': 'உதவியாளர்களைத் தேடு',
      'No helpers found': 'உதவியாளர்கள் காணப்படவில்லை',
      'View Profile': 'சுயவிவரம் பார்க்கவும்',
      'Rate Helper': 'உதவியாளரை மதிப்பிடவும்',
      'Submit Review': 'விமர்சனம் சமர்ப்பிக்கவும்',
      'No notifications': 'அறிவிப்புகள் இல்லை',
      'Mark as read': 'படித்ததாக குறிக்கவும்',
      'Clear all': 'அனைத்தையும் அழிக்கவும்',
      'Today': 'இன்று',
      'Yesterday': 'நேற்று',
      'This week': 'இந்த வாரம்',
      'This month': 'இந்த மாதம்',
      'Welcome': 'வரவேற்பு',
      'Welcome!': 'வரவேற்கிறோம்!',
      'Good morning': 'காலை வணக்கம்',
      'Good afternoon': 'மதிய வணக்கம்',
      'Good evening': 'மாலை வணக்கம்',
      'Payment': 'பணம்',
      'Payments': 'பணம் செலுத்துதல்',
      'Amount': 'தொகை',
      'Pay Now': 'இப்போது பணம் செலுத்து',
      'Payment Successful': 'பணம் செலுத்தல் வெற்றி',
      'Payment Failed': 'பணம் செலுத்தல் தோல்வி',
      'About Us': 'எங்களைப் பற்றி',
      'Help & Support': 'உதவி மற்றும் ஆதரவு',
      'Contact Us': 'எங்களைத் தொடர்பு கொள்ளவும்',
      'Rate': 'மதிப்பிடு',
      'Review': 'விமர்சனம்',
      'My Jobs': 'என் வேலைகள்',
      'Job History': 'வேலை வரலாறு',
      'Logout': 'வெளியேறு',
      'Account': 'கணக்கு',
      'Helpee Account': 'உதவி கோரும் கணக்கு',
      'Dark Mode': 'இருண்ட பயன்முறை',
      'Name': 'பெயர்',
      'Email': 'மின்னஞ்சல்',
      'Phone': 'தொலைபேசி',
      'Address': 'முகவரி',
      'Date': 'தேதி',
      'Time': 'நேரம்',
      'Location': 'இடம்',
      'Description': 'விவரம்',
      'Rating': 'மதிப்பீடு',
      'Reviews': 'விமர்சனங்கள்',
      'Contact': 'தொடர்பு',
      'Message': 'செய்தி',
      'Send Message': 'செய்தி அனுப்பு',
      'Call': 'அழைப்பு',
      'Distance': 'தூரம்',
      'Nearby': 'அருகில்',
      'Price': 'விலை',
      'Duration': 'காலம்',
      'No jobs available': 'வேலைகள் இல்லை',
      'No jobs for': 'வேலைகள் இல்லை',
      'No jobs scheduled for this day':
          'இந்த நாளுக்கு வேலைகள் திட்டமிடப்படவில்லை',
      'Pending Jobs': 'நிலுவையில் உள்ள வேலைகள்',
      'No data available': 'தரவு இல்லை',
      'Try again': 'மீண்டும் முயற்சி செய்யவும்',
      'Refresh': 'புதுப்பிக்கவும்',
      'Something went wrong': 'ஏதோ தவறு நடந்தது',
      'Please try again later': 'பின்னர் முயற்சி செய்யவும்',
      'Internet connection required': 'இணைய இணைப்பு தேவை',
      'Check your connection': 'உங்கள் இணைப்பை சரிபார்க்கவும்',
      'Update Available': 'புதுப்பிப்பு கிடைக்கிறது',
      'Update Now': 'இப்போது புதுப்பிக்கவும்',
      'Skip': 'தவிர்',
      'Help': 'உதவி',
      'Support': 'ஆதரவு',
      'January': 'ஜனவரி',
      'February': 'பிப்ரவரி',
      'March': 'மார்ச்',
      'April': 'ஏப்ரல்',
      'May': 'மே',
      'June': 'ஜூன்',
      'July': 'ஜூலை',
      'August': 'ஆகஸ்ட்',
      'September': 'செப்டம்பர்',
      'October': 'அக்டோபர்',
      'November': 'நவம்பர்',
      'December': 'டிசம்பர்',
      'th': 'ம்',
      'st': 'ம்',
      'nd': 'ம்',
      'rd': 'ம்',
      'Job Date': 'வேலை தேதி',
      'Job Time': 'வேலை நேரம்',
      'Job Location': 'வேலை இடம்',
      'Job Type': 'வேலை வகை',
      'Job Title': 'வேலை தலைப்பு',
      'Job Additional Details': 'வேலை கூடுதல் விவரங்கள்',
      'Job Description': 'வேலை விவரம்',
      'Job Status': 'வேலை நிலை',
      'Request Pending': 'கோரிக்கை நிலுவையில்',
      'Waiting for Helper': 'உதவியாளருக்காக காத்திருக்கிறது',
      'Request Created': 'கோரிக்கை உருவாக்கப்பட்டது',
      'Priority': 'முன்னுரிமை',
      'Visibility': 'பார்வை',
      'Public': 'பொது',
      'Private': 'தனிப்பட்ட',
      'Estimated Response': 'மதிப்பிட்ட பதில்',
      'Within 2 hours': '2 மணி நேரத்திற்குள்',
      'Available Actions': 'கிடைக்கும் செயல்கள்',
      'Edit Request': 'கோரிக்கையை திருத்து',
      'Cancel Request': 'கோரிக்கையை ரத்து செய்',
      'Keep Request': 'கோரிக்கையை வைத்திரு',
      'Edit Profile': 'சுயவிவரத்தை திருத்து',
      'Push Notifications': 'அழுத்த அறிவிப்புகள்',
      'Save Changes': 'மாற்றங்களைச் சேமி',
      'Search Helpers': 'உதவியாளர்களைத் தேடு',
      'All': 'அனைத்தும்',
      'Available Now': 'இப்போது கிடைக்கிறது',
      'Top Rated': 'சிறந்த மதிப்பீடு',
      'Quick Actions': 'விரைவான செயல்கள்',
      'Request Help': 'உதவி கோரவும்',
      'Find Helpers': 'உதவியாளர்களைக் கண்டுபிடி',
      'Need Help?': 'உதவி தேவையா?',
      'Get started by creating your first job request or browse available helpers in your area.':
          'உங்கள் முதல் வேலை கோரிக்கையை உருவாக்குங்கள் அல்லது உங்கள் பகுதியில் கிடைக்கும் உதவியாளர்களைப் பார்க்கவும்.',
      'Create Job Request': 'வேலை கோரிக்கை உருவாக்கவும்',
      'How can we help you today?':
          'இன்று நாங்கள் உங்களுக்கு எப்படி உதவ முடியும்?',
      'Select Location': 'இடத்தைத் தேர்ந்தெடுக்கவும்',
      'Selected Address': 'தேர்ந்தெடுக்கப்பட்ட முகவரி',
      'Enter address manually': 'முகவரியை கையாலே உள்ளிடவும்',
      'Interactive Map': 'ஊடாடும் வரைபடம்',
      'Getting Location...': 'இடம் பெறுகிறது...',
      'Tap on the map to select a location':
          'இடத்தைத் தேர்ந்தெடுக்க வரைபடத்தில் தட்டவும்',
      'Selected Location': 'தேர்ந்தெடுக்கப்பட்ட இடம்',
      'Confirm Location': 'இடத்தை உறுதிப்படுத்தவும்',
      'Select Current Address': 'தற்போதைய முகவரியைத் தேர்ந்தெடுக்கவும்',
      'Job request created successfully!':
          'வேலை கோரிக்கை வெற்றிகரமாக உருவாக்கப்பட்டது!',
      'Job request updated successfully!':
          'வேலை கோரிக்கை வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      'Profile updated successfully!':
          'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      'Login successful!': 'உள்நுழைவு வெற்றிகரமாக!',
      'Registration successful!': 'பதிவு வெற்றிகரமாக!',
      'We\'re finding the best helpers for you. You\'ll be notified once someone accepts.':
          'நாங்கள் உங்களுக்கு சிறந்த உதவியாளர்களைக் கண்டுபிடிக்கிறோம். யாராவது ஏற்றுக்கொண்டால் உங்களுக்கு அறிவிப்பு அனுப்பப்படும்.',
    },
  };

  /// Initialize the localization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('selected_language') ?? englishCode;
      _isInitialized = true;
      print(
          '✅ LocalizationService initialized with language: $_currentLanguage');
      notifyListeners();
    } catch (e) {
      print('Error initializing LocalizationService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get translated text
  String translate(String text) {
    if (_currentLanguage == englishCode) {
      return text;
    }

    // Check offline translations first
    if (_offlineTranslations.containsKey(_currentLanguage)) {
      final translations = _offlineTranslations[_currentLanguage]!;
      if (translations.containsKey(text)) {
        print(
            '🔄 Translating "$text" to "${translations[text]}" ($_currentLanguage)');
        return translations[text]!;
      }
    }

    // Return original text if no translation found
    print('⚠️ No translation found for "$text" in $_currentLanguage');
    return text;
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    try {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      print('✅ Language changed to: $languageCode');
      notifyListeners();
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return [englishCode, sinhalaCode, tamilCode];
  }

  /// Get native language name
  String getNativeLanguageName(String languageCode) {
    switch (languageCode) {
      case englishCode:
        return 'English';
      case sinhalaCode:
        return 'සිංහල';
      case tamilCode:
        return 'தமிழ்';
      default:
        return 'English';
    }
  }
}

/// Extension to make translation easier
extension TranslationExtension on String {
  String tr() {
    return LocalizationService().translate(this);
  }
}
