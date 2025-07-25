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

      // Information Page
      'Helping Hands': 'උදව්කාරී අත්',
      'Connecting Hearts, Building Communities':
          'හදවත් සම්බන්ධ කරමින්, ප්‍රජාවන් ගොඩ නඟමින්',
      'What is Helping Hands?': 'උදව්කාරී අත් යනු කුමක්ද?',
      'Helping Hands is a community-driven platform that connects people who need assistance with everyday tasks to skilled helpers who can provide those services. Our mission is to build stronger communities by making help accessible and creating opportunities for meaningful connections.':
          'උදව්කාරී අත් යනු එදිනෙදා කාර්යයන් සඳහා උදව් අවශ්‍ය පුද්ගලයින්ට එම සේවාවන් සැපයිය හැකි දක්ෂ උදව්කරුවන් සම්බන්ධ කරන ප්‍රජා මුලික වේදිකාවකි. උදව් ලබා ගැනීමට ඉඩ සළසා අර්ථවත් සම්බන්ධතා සඳහා අවස්ථා නිර්මාණය කිරීමෙන් ශක්තිමත් ප්‍රජාවන් ගොඩ නැගීම අපගේ මෙහෙවරයි.',
      'What is a Helpee?': 'උදව් ඉල්ලන්නෙකු යනු කුමක්ද?',
      'A Helpee is someone who needs assistance with various tasks such as house cleaning, gardening, cooking, elderly care, tutoring, or any other daily activities. Helpees can post job requests, browse available helpers, and hire the right person for their needs with transparent pricing and secure payments.':
          'උදව් ඉල්ලන්නෙකු යනු ගෘහ පිරිසිදු කිරීම, උද්‍යාන කර්මාන්තය, ආහාර පිසීම, වයස්ගත සේවය, ගුරුකම් කිරීම හෝ වෙනත් දෛනික ක්‍රියාකාරකම් වැනි විවිධ කාර්යයන් සඳහා උදව් අවශ්‍ය කෙනෙකි. උදව් ඉල්ලන්නන්ට කාර්ය ඉල්ලීම් ප්‍රකාශනය කිරීමට, ලබා ගත හැකි උදව්කරුවන් බැලීමට සහ විනිවිද දෘශ්‍ය මිල ගණන් සහ ආරක්ෂිත ගෙවීම් සමඟ ඔවුන්ගේ අවශ්‍යතා සඳහා සුදුසු පුද්ගලයා කුලියට ගැනීමට හැකිය.',
      'What is a Helper?': 'උදව්කරුවෙකු යනු කුමක්ද?',
      'A Helper is a skilled individual who offers their services to assist others with various tasks. Helpers can showcase their skills, set their rates, accept job requests, and earn money by helping their community. All helpers go through a verification process to ensure safety and quality service.':
          'උදව්කරුවෙකු යනු විවිධ කාර්යයන් සමඟ අන්‍යයන්ට උදව් කිරීමට ඔවුන්ගේ සේවාවන් ලබා දෙන දක්ෂ පුද්ගලයෙකි. උදව්කරුවන්ට ඔවුන්ගේ කුසලතා ප්‍රදර්ශනය කිරීමට, ඔවුන්ගේ ගාස්තු නියම කිරීමට, කාර්ය ඉල්ලීම් පිළිගැනීමට සහ ඔවුන්ගේ ප්‍රජාවට උදව් කිරීමෙන් මුදල් උපයා ගැනීමට හැකිය. ආරක්ෂාව සහ ගුණාත්මක සේවයක් සහතික කිරීම සඳහා සියලුම උදව්කරුවන් සත්‍යාපන ක්‍රියාවලියකට යටත් වේ.',
      'Key Features': 'ප්‍රධාන විශේෂාංග',
      'Secure Platform': 'ආරක්ෂිත වේදිකාව',
      'Verified users': 'සත්‍යාපිත පරිශීලකයින්',
      'Real-time Chat': 'තාත්කාලික කතාබස්',
      'Instant communication': 'ක්ෂණික සන්නිවේදනය',
      'Safe Payments': 'ආරක්ෂිත ගෙවීම්',
      'Secure transactions': 'ආරක්ෂිත ගනුදෙනු',
      'Rating System': 'ශ්‍රේණිගත කිරීමේ ක්‍රමය',
      'Quality assurance': 'ගුණාත්මක සහතිකය',
      'Join Our Community': 'අපගේ ප්‍රජාවට සම්බන්ධ වන්න',
      'Whether you need help or want to help others, Helping Hands makes it easy to connect with your community.':
          'ඔබට උදව් අවශ්‍ය වුවත් හෝ අන්‍යයන්ට උදව් කිරීමට අවශ්‍ය වුවත්, උදව්කාරී අත් ඔබේ ප්‍රජාව සමඟ සම්බන්ධ වීම පහසු කරයි.',
      'Get Started': 'ආරම්භ කරන්න',

      // Authentication Pages
      'Helper Portal': 'උදව්කරු ද්වාරය',
      'Helpee Portal': 'උදව් ඉල්ලන්නාගේ ද්වාරය',
      'I\'m a Helper': 'මම උදව්කරුවෙකි',
      'I\'m a Helpee': 'මම උදව් ඉල්ලන්නෙකි',
      'Ready to help others and earn money?':
          'අන්‍යයන්ට උදව් කර මුදල් උපයා ගැනීමට සුදානම්ද?',
      'Need help with daily tasks?': 'දෛනික කාර්යයන් සඳහා උදව් අවශ්‍යද?',
      'Username or Email': 'පරිශීලක නාමය හෝ විද්‍යුත් තැපෑල',
      'Enter your username or email':
          'ඔබේ පරිශීලක නාමය හෝ විද්‍යුත් තැපෑල ඇතුළත් කරන්න',
      'Password': 'මුරපදය',
      'Enter your password': 'ඔබේ මුරපදය ඇතුළත් කරන්න',
      'Please enter your username or email':
          'කරුණාකර ඔබේ පරිශීලක නාමය හෝ විද්‍යුත් තැපෑල ඇතුළත් කරන්න',
      'Please enter your password': 'කරුණාකර ඔබේ මුරපදය ඇතුළත් කරන්න',
      'Login': 'පිවිසෙන්න',
      'Logging in...': 'පිවිසෙමින්...',
      'Register': 'ලියාපදිංචි වන්න',
      'Don\'t have an account? ': 'ගිණුමක් නැතිද? ',
      'Login failed': 'පිවිසීම අසාර්ථකයි',
      'Login error: ': 'පිවිසීමේ දෝෂයක්: ',
      'Helpee Login': 'උදව් ඉල්ලන්නාගේ පිවිසීම',
      'Helper Login': 'උදව්කරුගේ පිවිසීම',
      'Login successful!': 'සාර්ථක පිවිසීමක්!',
      'Job request updated successfully!':
          'කාර්ය ඉල්ලීම සාර්ථකව යාවත්කාලීන විය!',
      'Profile updated successfully!': 'පැතිකඩ සාර්ථකව යාවත්කාලීන විය!',
      'Registration successful!': 'ලියාපදිංචි කිරීම සාර්ථකයි!',
      'We\'re finding the best helpers for you. You\'ll be notified once someone accepts.':
          'අපි ඔබට හොඳම උදව්කරුවන් සොයමින් සිටිමු. කවුරුහරි පිළිගත් කළ විට ඔබට දැනුම් දෙනු ඇත.',

      // Home Page Common
      'AI Bot Assist': 'AI Bot උදව්',
      'Helper Home': 'උදව්කරුගේ මුල් පිටුව',
      'Welcome back!': 'නැවත සාදරයෙන් පිළිගනිමු!',
      'Welcome back,': 'නැවත සාදරයෙන් පිළිගනිමු,',
      'Ready to help today?': 'අද උදව් කිරීමට සුදානම්ද?',
      'Job Opportunities': 'රැකියා අවස්ථා',
      'Private Requests': 'පෞද්ගලික ඉල්ලීම්',
      'Public Requests': 'පොදු ඉල්ලීම්',
      'User': 'පරිශීලකයා',

      // Menu and Settings
      'Report Issue': 'ගැටලුවක් වාර්තා කරන්න',
      'Are you sure you want to logout?': 'ඔබට ඇත්තටම ඉවත් වීමට අවශ්‍යද?',

      // About Us
      'Connecting Communities, One Task at a Time':
          'ප්‍රජාවන් සම්බන්ධ කරමින්, එක් කාර්යයකින්',
      'Our Mission': 'අපගේ මෙහෙවර',
      'To create a trusted platform that connects people who need household assistance with skilled helpers in their community. We believe in empowering individuals through meaningful work opportunities while making life easier for busy families.':
          'ගෘහස්ථ උදව් අවශ්‍ය පුද්ගලයින් ඔවුන්ගේ ප්‍රජාවේ දක්ෂ උදව්කරුවන් සමඟ සම්බන්ධ කරන විශ්වසනීය වේදිකාවක් නිර්මාණය කිරීම. කාර්යබහුල පවුල්වලට ජීවිතය පහසු කරමින් අර්ථවත් රැකියා අවස්ථා හරහා පුද්ගලයින් සවිබල ගැන්වීම අපි විශ්වාස කරමු.',
      'Our Vision': 'අපගේ දැක්ම',
      'To be Sri Lanka\'s leading household services platform, fostering a community where everyone can access reliable help and create sustainable livelihoods through dignified work.':
          'ශ්‍රී ලංකාවේ ප්‍රමුඛ ගෘහස්ථ සේවා වේදිකාව වීම, සෑම කෙනෙකුටම විශ්වසනීය උදව් ලබා ගැනීමට සහ ගෞරවනීය වැඩ හරහා තිරසාර ජීවනෝපාය නිර්මාණය කිරීමට හැකි ප්‍රජාවක් වර්ධනය කිරීම.',
      'Our Values': 'අපගේ වටිනාකම්',
      '• Trust & Safety: Verified helpers and secure payments\n• Quality Service: Skilled professionals you can rely on\n• Community: Supporting local workers and families\n• Transparency: Clear pricing and honest reviews\n• Respect: Treating everyone with dignity and fairness':
          '• විශ්වාසය සහ ආරක්ෂාව: සත්‍යාපිත උදව්කරුවන් සහ ආරක්ෂිත ගෙවීම්\n• ගුණාත්මක සේවය: ඔබට විශ්වාස කළ හැකි දක්ෂ වෘත්තිකයන්\n• ප්‍රජාව: ප්‍රාදේශීය කම්කරුවන් සහ පවුල්වලට සහාය\n• විනිවිදභාවය: පැහැදිලි මිල ගණන් සහ අවංක සමාලෝචන\n• ගෞරවය: සියල්ලන්ට ගෞරවයෙන් සහ සාධාරණව සැලකීම',
      'How It Works': 'මෙය ක්‍රියා කරන්නේ කෙසේද',
      '1. Post Your Request: Describe what help you need\n2. Get Matched: Browse qualified helpers in your area\n3. Chat & Hire: Connect directly with your chosen helper\n4. Service Delivered: Get the job done professionally\n5. Pay Securely: Cashless transactions through the app\n6. Rate & Review: Share your experience with the community':
          '1. ඔබේ ඉල්ලීම පළ කරන්න: ඔබට අවශ්‍ය උදව විස්තර කරන්න\n2. ගැලපීම ලබා ගන්න: ඔබේ ප්‍රදේශයේ සුදුසුකම් ලත් උදව්කරුවන් බලන්න\n3. කතාබහ කර කුලියට ගන්න: ඔබ තෝරාගත් උදව්කරුවා සමඟ සෘජුව සම්බන්ධ වන්න\n4. සේවය ලබා දෙන්න: වෘත්තීයව කාර්යය සම්පූර්ණ කරන්න\n5. ආරක්ෂිතව ගෙවන්න: යෙදුම හරහා මුදල් නොමැති ගනුදෙනු\n6. ශ්‍රේණිගත කර සමාලෝචනය කරන්න: ප්‍රජාව සමඟ ඔබේ අත්දැකීම් බෙදා ගන්න',

      // Job Request Form
      'Enter job title': 'රැකියා මාතෘකාව ඇතුළත් කරන්න',
      'Select Category': 'කාණ්ඩය තෝරන්න',
      'Select Date': 'දිනය තෝරන්න',
      'Select Time': 'වේලාව තෝරන්න',
      'Additional Details': 'අමතර විස්තර',
      'Enter any additional notes or requirements':
          'ඕනෑම අමතර සටහන් හෝ අවශ්‍යතා ඇතුළත් කරන්න',
      'Private Job': 'පෞද්ගලික රැකියාව',
      'Public Job': 'පොදු රැකියාව',
      'Search for a specific helper': 'නිශ්චිත උදව්කරුවෙකු සොයන්න',
      'Create Job': 'රැකියාව නිර්මාණය කරන්න',
      'Creating job request...': 'රැකියා ඉල්ලීම නිර්මාණය කරමින්...',

      // Activity and Status
      'Active Jobs': 'ක්‍රියාකාරී රැකියා',
      'Recent Activity': 'මෑත ක්‍රියාකාරකම්',
      'No recent activity': 'මෑත ක්‍රියාකාරකම් නැත',
      'View Details': 'විස්තර බලන්න',
      'Mark as Complete': 'සම්පූර්ණ ලෙස සලකුණු කරන්න',
      'In Progress': 'ක්‍රියාත්මක',
      'Not Started': 'ආරම්භ කර නැත',

      // Profile and Settings
      'First Name': 'මුල් නම',
      'Last Name': 'අවසන් නම',
      'Phone Number': 'දුරකථන අංකය',
      'Gender': 'ලිංගය',
      'Date of Birth': 'උපන් දිනය',
      'Male': 'පුරුෂ',
      'Female': 'ස්ත්‍රී',
      'Other': 'වෙනත්',
      'Bio': 'ජීව විස්තරය',
      'Skills': 'කුසලතා',
      'Experience': 'අත්දැකීම්',
      'Hourly Rate': 'පැය ගාස්තුව',
      'LKR': 'රුපියල්',
      'per hour': 'පැයකට',

      // Profile Image Upload
      'Tap to change profile photo':
          'ප්‍රොෆයිල් ඡායාරූපය වෙනස් කිරීමට ටැප් කරන්න',
      'Select Profile Photo': 'ප්‍රොෆයිල් ඡායාරූපය තෝරන්න',
      'Camera': 'කැමරාව',
      'Gallery': 'ගැලරිය',
      'Uploading photo...': 'ඡායාරූපය උඩුගත කරමින්...',
      'Profile photo updated successfully!':
          'ප්‍රොෆයිල් ඡායාරූපය සාර්ථකව යාවත්කාලීන කරන ලදී!',
      'Failed to select image': 'ඡායාරූපය තෝරා ගැනීමට අසමත් විය',
      'Failed to upload image': 'ඡායාරූපය උඩුගත කිරීමට අසමත් විය',

      // Notifications
      'New Job Request': 'නව රැකියා ඉල්ලීම',
      'Job Accepted': 'රැකියාව පිළිගන්නා ලදී',
      'Job Completed': 'රැකියාව සම්පූර්ණ විය',
      'Payment Received': 'ගෙවීම ලැබුණි',
      'New Message': 'නව පණිවිඩය',
      'Job Started': 'රැකියාව ආරම්භ විය',
      'Job Cancelled': 'රැකියාව අවලංගු විය',

      // Days and Time
      'Monday': 'සඳුදා',
      'Tuesday': 'අඟහරුවාදා',
      'Wednesday': 'බදාදා',
      'Thursday': 'බ්‍රහස්පතින්දා',
      'Friday': 'සිකුරාදා',
      'Saturday': 'සෙනසුරාදා',
      'Sunday': 'ඉරිදා',
      'AM': 'පෙ.ව.',
      'PM': 'ප.ව.',

      // Common Actions
      'Accept': 'පිළිගන්න',
      'Reject': 'ප්‍රතික්ෂේප කරන්න',
      'Start Job': 'රැකියාව ආරම්භ කරන්න',
      'Complete Job': 'රැකියාව සම්පූර්ණ කරන්න',
      'Send': 'යවන්න',
      'Reply': 'පිළිතුරු දෙන්න',
      'Upload Photo': 'ඡායාරූපය උඩුගත කරන්න',
      'Take Photo': 'ඡායාරූපය ගන්න',
      'Choose from Gallery': 'ගැලරියෙන් තෝරන්න',

      // Chat and Communication
      'Type a message...': 'පණිවිඩයක් ටයිප් කරන්න...',
      'Voice Call': 'හඬ ඇමතුම',
      'Video Call': 'වීඩියෝ ඇමතුම',
      'Last seen': 'අවසන්වරට දුටුවේ',
      'Typing...': 'ටයිප් කරමින්...',

      // Payment and Billing
      'Total Amount': 'මුළු ගුණය',
      'Service Fee': 'සේවා ගාස්තුව',
      'Platform Fee': 'වේදිකා ගාස්තුව',
      'Tax': 'බදු',
      'Discount': 'වට්ටම',
      'Final Amount': 'අවසන් ගුණය',
      'Payment Method': 'ගෙවීමේ ක්‍රමය',
      'Credit Card': 'ක්‍රෙඩිට් කාඩ්',
      'Debit Card': 'ඩෙබිට් කාඩ්',
      'Digital Wallet': 'ඩිජිටල් මුදල් පසුම්බිය',
      'Bank Transfer': 'බැංකු මාරු කිරීම',
      'Cash': 'මුදල්',

      // Ratings and Reviews
      'Rate this service': 'මෙම සේවාව ශ්‍රේණිගත කරන්න',
      'Write a review': 'සමාලෝචනයක් ලියන්න',
      'Submit Rating': 'ශ්‍රේණිගත කිරීම ඉදිරිපත් කරන්න',
      'Thank you for your feedback': 'ඔබේ ප්‍රතිපෝෂණයට ස්තූතියි',
      'stars': 'තරු',
      'Excellent': 'විශිෂ්ට',
      'Good': 'හොඳ',
      'Average': 'සාමාන්‍ය',
      'Poor': 'දුර්වල',
      'Terrible': 'භයානක',

      // Error Messages
      'Network error': 'ජාල දෝෂයක්',
      'Please check your internet connection':
          'කරුණාකර ඔබේ අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කරන්න',
      'Failed to load data': 'දත්ත පූරණය කිරීමට අසමත් විය',
      'Invalid input': 'වැරදි ආදානය',
      'Required field': 'අවශ්‍ය ක්ෂේත්‍රය',
      'Please fill all required fields':
          'කරුණාකර සියලුම අවශ්‍ය ක්ෂේත්‍ර පුරවන්න',

      // Calendar and Scheduling
      'Schedule': 'කාලසටහන',
      'Unavailable': 'ලබා ගත නොහැකිය',
      'Booked': 'වෙන්කර ගත්',
      'Free': 'නිදහස්',
      'Working Hours': 'වැඩ කරන වේලාවන්',
      'Break Time': 'විරාම කාලය',

      // Additional Menu and Profile
      'Verified Helper': 'සත්‍යාපිත උදව්කරුවා',
      'Analytics': 'විශ්ලේෂණ',
      'Earnings': 'ආදායම',
      'Support & Information': 'සහාය සහ තොරතුරු',
      'Terms & Conditions': 'නියම සහ කොන්දේසි',
      'Privacy Policy': 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය',
      'Opening': 'විවෘත කරමින්',
      'Logged out successfully': 'සාර්ථකව ඉවත් විය',

      // Search and Filter
      'Select Helper': 'උදව්කරුවා තෝරන්න',
      'Search by name, skill, or location...':
          'නම, කුසලතාව හෝ ස්ථානය අනුව සොයන්න...',
      'House Cleaning': 'ගෘහ පිරිසිදු කිරීම',
      'Gardening': 'උද්‍යාන කර්මාන්තය',
      'Cooking': 'ආහාර පිසීම',
      'Distance unknown': 'දුර නොදනී',
      'Unknown Helper': 'නොදන්නා උදව්කරුවා',
      'Professional helper ready to assist you':
          'ඔබට උදව් කිරීමට සුදානම් වෘත්තිකයෙකු',
      'Unable to load helpers': 'උදව්කරුවන් පූරණය කිරීමට නොහැකිය',
      'Unknown error': 'නොදන්නා දෝෂයක්',
      'Retry': 'නැවත උත්සාහ කරන්න',
      'Try adjusting your search terms or filters to find more helpers.':
          'වැඩි උදව්කරුවන් සොයා ගැනීමට ඔබේ සෙවුම් පද හෝ පෙරහන් සකස් කිරීමට උත්සාහ කරන්න.',
      'Clear Search': 'සෙවුම ඉවත් කරන්න',
      'Failed to load helpers: ': 'උදව්කරුවන් පූරණය කිරීමට අසමත් විය: ',

      // Additional New Terms (Non-Duplicates Only)
      'Request Helper': 'උදව්කරුවෙකු ඉල්ලන්න',
      'Select job type': 'රැකියා වර්ගය තෝරන්න',
      'Please select a job type': 'කරුණාකර රැකියා වර්ගයක් තෝරන්න',
      'Job Requirements': 'රැකියා අවශ්‍යතා',
      'Enter a clear job title': 'පැහැදිලි රැකියා මාතෘකාවක් ඇතුළත් කරන්න',
      'Please enter a job title': 'කරුණාකර රැකියා මාතෘකාවක් ඇතුළත් කරන්න',
      'Enter job location': 'රැකියා ස්ථානය ඇතුළත් කරන්න',
      'Please enter the job location': 'කරුණාකර රැකියා ස්ථානය ඇතුළත් කරන්න',
      'Pick Location on Map': 'සිතියමේ ස්ථානය තෝරන්න',
      'Location Selected ✓': 'ස්ථානය තෝරාගත් ✓',
      'Coordinates: ': 'ඛණ්ඩාංක: ',
      'Default hourly rate for this category: LKR ':
          'මෙම කාණ්ඩය සඳහා සාමාන්‍ය පැය ගාස්තුව: LKR ',
      'Unknown Job': 'නොදන්නා රැකියාව',
      'km': 'කිමී',
      'Unable to load profile data': 'පැතිකඩ දත්ත පූරණය කළ නොහැක',
      'Personal Information': 'පුද්ගලික තොරතුරු',
      'NIC Number': 'ජා.හැ. අංකය',
      'Province': 'පළාත',
      'Postal Code': 'තැපැල් කේතය',
      'Emergency Contact Name': 'හදිසි සම්බන්ධතා නම',
      'Emergency Contact Phone': 'හදිසි සම්බන්ධතා දුරකථනය',
      'Relationship': 'සම්බන්ධතාවය',
      'Parent': 'දෙමාපියන්',
      'Sibling': 'සහෝදරයා',
      'Spouse': 'කලත්‍රයා',
      'Friend': 'මිත්‍රයා',
      'Relative': 'ඥාතියා',
      'Payment Summary': 'ගෙවීම් සාරාංශය',
      'Service Charge': 'සේවා ගාස්තුව',
      'Visa, Mastercard, Amex': 'Visa, Mastercard, Amex',
      'Pay cash when helper arrives': 'උදව්කරුවා පැමිණි විට මුදල් ගෙවන්න',
      'PayPal, Google Pay, Apple Pay': 'PayPal, Google Pay, Apple Pay',
      'Direct bank transfer': 'සෘජු බැංකු මාරු කිරීම',
      'Saved Cards': 'සුරකින ලද කාඩ්',
      'Expires': 'කල් ඉකුත් වන්නේ',
      'Your payment information is encrypted and secure. We never store your card details.':
          'ඔබේ ගෙවීම් තොරතුරු සංකේතනය කර ආරක්ෂිත ය. අපි කිසි විටෙකත් ඔබේ කාඩ් විස්තර ගබඩා නොකරමු.',
      'Pay LKR': 'LKR ගෙවන්න',
      'Job Not Started': 'රැකියාව ආරම්භ කර නැත',
      'Started': 'ආරම්භ කළා',
      'Paused': 'නතර කළා',
      'Confirmed': 'තහවුරු කළා',
      'Helper Assigned': 'උදව්කරුවා පවරා ඇත',
      'Awaiting Helper': 'උදව්කරුවා සඳහා රැඳී සිටිමින්',
      'All notifications marked as read':
          'සියලුම දැනුම්දීම් කියවූ ලෙස සලකුණු කර ඇත',
      'Error loading notifications: ': 'දැනුම්දීම් පූරණය කිරීමේ දෝෂයක්: ',
      'No notifications yet': 'තවම දැනුම්දීම් නැත',
      'We\'ll let you know when something important happens.':
          'වැදගත් දෙයක් සිදු වූ විට අපි ඔබට දන්වන්නෙමු.',
      'Write Review': 'සමාලෝචනය ලියන්න',
      'Rate Service': 'සේවයට ශ්‍රේණියක් දෙන්න',
      'How was your experience?': 'ඔබේ අත්දැකීම කෙසේද?',
      'Tell others about your experience': 'ඔබේ අත්දැකීම ගැන අන් අයට කියන්න',
      'Review submitted successfully!': 'සමාලෝචනය සාර්ථකව ඉදිරිපත් කළා!',
      'Loading earnings analytics...': 'ආදායම් විශ්ලේෂණ පූරණය කරමින්...',
      'Error loading earnings data': 'ආදායම් දත්ත පූරණය කිරීමේ දෝෂයක්',
      'Export Data': 'දත්ත නිර්යාත කරන්න',
      'Total Earnings': 'මුළු ආදායම',
      'Jobs Completed': 'සම්පූර්ණ කළ රැකියා',
      'This Period': 'මෙම කාලය',
      'Earnings Chart': 'ආදායම් ප්‍රස්ථාරය',
      'Category Breakdown': 'කාණ්ඩ බෙදීම',
      'Performance Metrics': 'කාර්ය සාධන මිනුම්',
      'Recent Jobs': 'මෑත රැකියා',
      'Invalid email address': 'වලංගු නොවන විද්‍යුත් තැපැල් ලිපිනය',
      'Password too short': 'මුරපදය ඉතා කෙටිය',
      'Passwords do not match': 'මුරපද නොගැලපේ',
      'Invalid phone number': 'වලංගු නොවන දුරකථන අංකය',
      'Please select a date': 'කරුණාකර දිනයක් තෝරන්න',
      'Please select a time': 'කරුණාකර වේලාවක් තෝරන්න',
      'Field cannot be empty': 'ක්ෂේත්‍රය හිස් විය නොහැක',
      'Please enter a valid amount': 'කරුණාකර වලංගු මුදලක් ඇතුළත් කරන්න',
      'View All': 'සියල්ල බලන්න',
      'See More': 'තව බලන්න',
      'Show Less': 'අඩුවෙන් පෙන්වන්න',
      'Load More': 'තව පූරණය කරන්න',
      'Read More': 'තව කියවන්න',
      'Contact Helper': 'උදව්කරුවා සම්බන්ධ කරන්න',
      'Hire Helper': 'උදව්කරුවා කුලියට ගන්න',
      'Cancel Job': 'රැකියාව අවලංගු කරන්න',
      'Mark Job Complete': 'රැකියාව සම්පූර්ණ ලෙස සලකුණු කරන්න',
      'Confirm Payment': 'ගෙවීම තහවුරු කරන්න',
      'Copy': 'පිටපත් කරන්න',
      'Paste': 'අලවන්න',
      'Select All': 'සියල්ල තෝරන්න',
      'Deselect All': 'සියල්ල අතහරින්න',
      'Just now': 'මේ ම දැන්',
      'minutes ago': 'මිනිත්තු කිහිපයකට පෙර',
      'hours ago': 'පැය කිහිපයකට පෙර',
      'days ago': 'දින කිහිපයකට පෙර',
      'weeks ago': 'සති කිහිපයකට පෙර',
      'months ago': 'මාස කිහිපයකට පෙර',
      'years ago': 'වර්ෂ කිහිපයකට පෙර',
      'All Day': 'මුළු දිනයම',
      'Flexible': 'නම්‍යශීලී',
      'Elder Care': 'වයස්ගත සේවය',
      'Tutoring': 'ගුරුකම් කිරීම',
      'Pet Care': 'සුරතල් සත්ව රැකවරණය',
      'Moving Help': 'ගෙනයාමේ උදව්',
      'Handyman': 'අත්කම්කරුවා',
      'Babysitting': 'ළමා රැකවරණය',
      'Home Repairs': 'ගෘහ අලුත්වැඩියාව',
      'Car Washing': 'කාර් සේදීම',
      'Laundry': 'රෙදි සේදීම',
      'Shopping': 'සාප්පු සවාරි',
      'Delivery': 'බෙදාහැරීම',
      'Event Help': 'උත්සව උදව්',
      'Helper Dashboard': 'උදව්කරු උපකරණ පුවරුව',
      'Helpee Dashboard': 'උදව් ඉල්ලන්නාගේ උපකරණ පුවරුව',
      'Helper Profile': 'උදව්කරු පැතිකඩ',
      'Helpee Profile': 'උදව් ඉල්ලන්නාගේ පැතිකඩ',
      'Request from Helpee': 'උදව් ඉල්ලන්නාගෙන් ඉල්ලීම',
      'Response from Helper': 'උදව්කරුගෙන් ප්‍රතිචාරය',
      'Helpee Rating': 'උදව් ඉල්ලන්නාගේ ශ්‍රේණිගත කිරීම',
      'Helper Rating': 'උදව්කරුගේ ශ්‍රේණිගත කිරීම',
      'Available Helpers': 'ලබා ගත හැකි උදව්කරුවන්',
      'Helper Requests': 'උදව්කරු ඉල්ලීම්',
      'Helper Verification': 'උදව්කරු සත්‍යාපනය',
      'Background Check': 'පසුබිම් පරීක්ෂාව',
      'ID Verification': 'හැඳුනුම්පත් සත්‍යාපනය',
      'Skill Assessment': 'කුසලතා තක්සේරුව',
      'Account Security': 'ගිණුම් ආරක්ෂාව',
      'Two-Factor Authentication': 'ද්වි-සාධක සත්‍යාපනය',
      'Security Questions': 'ආරක්ෂක ප්‍රශ්න',
      'Privacy Settings': 'රහස්‍යතා සැකසීම්',
      'Data Protection': 'දත්ත ආරක්ෂාව',
      'Location Sharing': 'ස්ථාන බෙදාගැනීම',
      'Profile Visibility': 'පැතිකඩ දෘශ්‍යතාව',
      'Notification Preferences': 'දැනුම්දීම් මනාපයන්',
      'Email Notifications': 'විද්‍යුත් තැපැල් දැනුම්දීම්',
      'SMS Notifications': 'SMS දැනුම්දීම්',
      'App Permissions': 'යෙදුම් අවසර',
      'Camera Access': 'කැමරා ප්‍රවේශය',
      'Location Access': 'ස්ථාන ප්‍රවේශය',
      'Microphone Access': 'මයික්‍රොෆෝන ප්‍රවේශය',
      'Storage Access': 'ගබඩා ප්‍රවේශය',
      'Emergency': 'හදිසි',
      'Urgent': 'ඉක්මන්',
      'High Priority': 'ඉහළ ප්‍රමුඛතාවය',
      'Low Priority': 'අඩු ප්‍රමුඛතාවය',
      'Normal Priority': 'සාමාන්‍ය ප්‍රමුඛතාවය',
      'Estimated Time': 'ගණන් බලන ලද කාලය',
      'Actual Time': 'සැබෑ කාලය',
      'Response Time': 'ප්‍රතිචාර කාලය',
      'Completion Rate': 'සම්පූර්ණ කිරීමේ අනුපාතය',
      'Success Rate': 'සාර්ථක අනුපාතය',
      'Satisfaction Rate': 'තෘප්තිමත් අනුපාතය',
      'Availability Status': 'ලබා ගත හැකි තත්ත්වය',
      'Work History': 'කාර්ය ඉතිහාසය',
      'Employment Type': 'රැකියා වර්ගය',
      'Part Time': 'අර්ධකාලීන',
      'Full Time': 'පූර්ණකාලීන',
      'Contract': 'කොන්ත්‍රාත්තුව',
      'Freelance': 'නිදහස් කාර්යකරු',
      'Commission': 'කොමිස්',
      'Bonus': 'ප්‍රසාද දීමනාව',
      'Incentive': 'දිරිගැන්වීම',
      'Penalty': 'දඩය',
      'Refund': 'ආපසු ගෙවීම',
      'Compensation': 'වන්දි',
      'Tip': 'ප්‍රසාදය',
      'Service Guarantee': 'සේවා සහතිකය',
      'Quality Assurance': 'ගුණාත්මක සහතිකය',
      'Customer Satisfaction': 'පාරිභෝගික තෘප්තිමත් භාවය',
      'Feedback': 'ප්‍රතිපෝෂණය',
      'Complaint': 'පැමිණිල්ල',
      'Dispute': 'ආරවුල',
      'Resolution': 'විසඳුම',
      'Investigation': 'විමර්ශනය',
      'Appeal': 'අභියාචනය',

      // AI Bot & Chat Features
      'Hello! I\'m your AI assistant for Helping Hands. I can help you create job requests through natural conversation. Just tell me what kind of help you need!':
          'ආයුබෝවන්! මම උදව්කාරී අත් සඳහා වූ AI සහායකයා. ස්වභාවික කතාබහ හරහා කාර්ය ඉල්ලීම් නිර්මාණය කිරීමට මට ඔබට උදව් කළ හැකිය. ඔබට කුමන ආකාරයේ උදව්ක් අවශ්‍යද?',
      'Sorry, I\'m having trouble connecting to the AI service. Please try again later.':
          'කණගාටුයි, AI සේවයට සම්බන්ධ වීමට මට ගැටලුවක් ඇත. කරුණාකර පසුව නැවත උත්සාහ කරන්න.',
      'Connecting to AI assistant...': 'AI සහායකයා සමඟ සම්බන්ධ වෙමින්...',
      'Job Request Progress': 'කාර්ය ඉල්ලීම ප්‍රගතිය',
      'Sorry, I didn\'t understand that.':
          'කණගාටුයි, මට එය තේරුම් ගත නොහැකි විය.',
      'Sorry, I\'m having trouble processing your request. Please try again.':
          'කණගාටුයි, ඔබේ ඉල්ලීම සැකසීමට මට ගැටලුවක් ඇත. කරුණාකර නැවත උත්සාහ කරන්න.',
      'Job Request Preview': 'කාර්ය ඉල්ලීම පූර්ව දර්ශනය',
      'Service Category': 'සේවා කාණ්ඩය',
      'Job Request Title': 'කාර්ය ඉල්ලීම මාතෘකාව',
      'Date & Time': 'දිනය සහ වේලාව',
      'Job Hourly Rate': 'කාර්ය පැය ගාස්තුව',
      '/hour': '/පැයට',
      'Not set': 'සකස් කර නැත',

      // About Us & Company Information
      'Connecting communities through trusted services':
          'විශ්වසනීය සේවා හරහා ප්‍රජාවන් සම්බන්ධ කිරීම',
      'To create a platform where skilled helpers can connect with people who need assistance, fostering trust, reliability, and community support. We believe in empowering individuals to earn income while helping others improve their quality of life.':
          'උදව් අවශ්‍ය පුද්ගලයින් සමඟ දක්ෂ උදව්කරුවන්ට සම්බන්ධ විය හැකි වේදිකාවක් නිර්මාණය කිරීම, විශ්වාසය, විශ්වසනීයත්වය සහ ප්‍රජා සහාය වර්ධනය කිරීම. අන් අයගේ ජීවන තත්ත්වය වැඩිදියුණු කිරීමට උදව් කරමින් මුදල් ඉපයීමට පුද්ගලයින් සවිබල ගැන්වීම අපි විශ්වාස කරමු.',
      'To become the leading platform for trusted household and personal services in Sri Lanka, where every helper is valued and every client receives exceptional service.':
          'ශ්‍රී ලංකාවේ විශ්වසනීය ගෘහස්ථ සහ පුද්ගලික සේවා සඳහා ප්‍රමුඛ වේදිකාව වීම, සෑම උදව්කරුවෙකුම අගය කරන සහ සෑම ගනුදෙනුකරුවෙකුම සුවිශේෂී සේවයක් ලබන ස්ථානයක්.',
      'Trust': 'විශ්වාසය',
      'Building confidence through verified profiles and secure transactions':
          'සත්‍යාපිත පැතිකඩ සහ ආරක්ෂිත ගනුදෙනු හරහා විශ්වාසය ගොඩනැගීම',
      'Quality': 'ගුණාත්මකභාවය',
      'Ensuring high standards in every service provided':
          'සැපයෙන සෑම සේවයකම ඉහළ ප්‍රමිතීන් සහතික කිරීම',
      'Community': 'ප්‍රජාව',
      'Creating connections that strengthen local communities':
          'ප්‍රාදේශීය ප්‍රජාවන් ශක්තිමත් කරන සම්බන්ධතා නිර්මාණය කිරීම',
      'Empowerment': 'සවිබල ගැන්වීම',
      'Enabling helpers to build sustainable income streams':
          'උදව්කරුවන්ට තිරසාර ආදායම් ධාරා ගොඩනැගීමට හැකියාව ලබා දීම',
      'Sign Up': 'ලියාපදිංචි වන්න',
      'Create your profile and showcase your skills':
          'ඔබේ පැතිකඩ නිර්මාණය කර ඔබේ කුසලතා ප්‍රදර්ශනය කරන්න',
      'Get Verified': 'සත්‍යාපනය ලබා ගන්න',
      'Complete verification for trust and safety':
          'විශ්වාසය සහ ආරක්ෂාව සඳහා සත්‍යාපනය සම්පූර්ණ කරන්න',
      'Browse Jobs': 'රැකියා පිරික්සන්න',
      'Find opportunities that match your expertise':
          'ඔබේ ප්‍රවීණතාවයට ගැලපෙන අවස්ථා සොයන්න',
      'Deliver Service': 'සේවය ලබා දෙන්න',
      'Provide excellent service to your clients':
          'ඔබේ ගනුදෙනුකරුවන්ට විශිෂ්ට සේවයක් ලබා දෙන්න',
      'Get Paid': 'ගෙවීම ලබා ගන්න',
      'Receive secure payments for your work':
          'ඔබේ කාර්යය සඳහා ආරක්ෂිත ගෙවීම් ලබා ගන්න',
      'App Version': 'යෙදුම් සංස්කරණය',

      // Job Detail Page
      'Loading job details...': 'කාර්ය විස්තර පූරණය කරමින්...',
      'Failed to load job details': 'කාර්ය විස්තර පූරණය කිරීමට අසමත් විය',
      'Job details': 'කාර්ය විස්තර',
      'PRIVATE': 'පෞද්ගලික',
      'PUBLIC': 'පොදු',
      'General Services': 'සාමාන්‍ය සේවා',
      'Not specified': 'නිශ්චිත කර නැත',
      'PENDING': 'අපේක්ෂිතයි',
      'ACCEPTED': 'පිළිගත්',
      'ONGOING': 'ක්‍රියාත්මක',
      'COMPLETED': 'සම්පූර්ණයි',
      'CANCELLED': 'අවලංගු කළා',

      // Help & Support
      'Live Chat': 'සජීවී කතාබස්',
      'Get instant help': 'ක්ෂණික උදව් ලබා ගන්න',
      'Call Us': 'අපට ඇමතුම් දෙන්න',
      'Search help topics...': 'උදව් මාතෘකා සොයන්න...',
      'Getting Started': 'ආරම්භ කිරීම',
      'Job Management': 'කාර්ය කළමනාකරණය',
      'Payment Issues': 'ගෙවීම් ගැටලු',
      'Account Settings': 'ගිණුම් සැකසීම්',
      'Technical Support': 'තාක්ෂණික සහාය',
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

      // Profile Image Upload
      'Tap to change profile photo': 'சுயவிவர புகைப்படத்தை மாற்ற தொடவும்',
      'Select Profile Photo': 'சுயவிவர புகைப்படத்தை தேர்ந்தெடுக்கவும்',
      'Camera': 'கேமரா',
      'Gallery': 'கேலரி',
      'Uploading photo...': 'புகைப்படம் பதிவேற்றப்படுகிறது...',
      'Profile photo updated successfully!':
          'சுயவிவர புகைப்படம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      'Failed to select image': 'படத்தை தேர்ந்தெடுக்க முடியவில்லை',
      'Failed to upload image': 'படத்தை பதிவேற்ற முடியவில்லை',

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

      // AI Bot & Chat Features
      'Hello! I\'m your AI assistant for Helping Hands. I can help you create job requests through natural conversation. Just tell me what kind of help you need!':
          'வணக்கம்! நான் உதவும் கைகளுக்கான AI உதவியாளர். இயற்கையான உரையாடலின் மூலம் வேலை கோரிக்கைகளை உருவாக்க உங்களுக்கு உதவ முடியும். உங்களுக்கு என்ன வகையான உதவி தேவை என்று சொல்லுங்கள்!',
      'Sorry, I\'m having trouble connecting to the AI service. Please try again later.':
          'மன்னிக்கவும், AI சேவையுடன் இணைப்பதில் சிக்கல் உள்ளது. பின்னர் மீண்டும் முயற்சி செய்யவும்.',
      'Connecting to AI assistant...': 'AI உதவியாளருடன் இணைக்கிறது...',
      'Job Request Progress': 'வேலை கோரிக்கை முன்னேற்றம்',
      'Sorry, I didn\'t understand that.':
          'மன்னிக்கவும், எனக்கு அது புரியவில்லை.',
      'Sorry, I\'m having trouble processing your request. Please try again.':
          'மன்னிக்கவும், உங்கள் கோரிக்கையை செயலாக்குவதில் சிக்கல் உள்ளது. மீண்டும் முயற்சி செய்யவும்.',
      'Job Request Preview': 'வேலை கோரிக்கை முன்னோட்டம்',
      'Service Category': 'சேவை பிரிவு',
      'Job Request Title': 'வேலை கோரிக்கை தலைப்பு',
      'Date & Time': 'தேதி மற்றும் நேரம்',
      'Job Hourly Rate': 'வேலை மணிநேர விலை',
      '/hour': '/மணி',
      'Not set': 'அமைக்கப்படவில்லை',

      // About Us & Company Information
      'Connecting communities through trusted services':
          'நம்பகமான சேவைகளின் மூலம் சமூகங்களை இணைத்தல்',
      'To create a platform where skilled helpers can connect with people who need assistance, fostering trust, reliability, and community support. We believe in empowering individuals to earn income while helping others improve their quality of life.':
          'உதவி தேவைப்படும் மக்களுடன் திறமையான உதவியாளர்கள் இணைய முடியும், நம்பிக்கை, நம்பகத்தன்மை மற்றும் சமூக ஆதரவை வளர்க்கும் ஒரு தளத்தை உருவாக்குவது. மற்றவர்களின் வாழ்க்கைத் தரத்தை மேம்படுத்த உதவும் போது வருமானம் ஈட்ட தனிநபர்களை அதிகாரப்படுத்துவதில் நாங்கள் நம்புகிறோம்.',
      'To become the leading platform for trusted household and personal services in Sri Lanka, where every helper is valued and every client receives exceptional service.':
          'ஸ்ரீலங்காவில் நம்பகமான வீட்டு மற்றும் தனிப்பட்ட சேவைகளுக்கான முன்னணி தளமாக மாறுவது, அங்கு ஒவ்வொரு உதவியாளரும் மதிக்கப்படுகிறார் மற்றும் ஒவ்வொரு வாடிக்கையாளரும் விதிவிலக்கான சேவையைப் பெறுகிறார்.',
      'Trust': 'நம்பிக்கை',
      'Building confidence through verified profiles and secure transactions':
          'சரிபார்க்கப்பட்ட சுயவிவரங்கள் மற்றும் பாதுகாப்பான பரிவர்த்தனைகள் மூலம் நம்பிக்கையை வளர்த்தல்',
      'Quality': 'தரம்',
      'Ensuring high standards in every service provided':
          'வழங்கப்படும் ஒவ்வொரு சேவையிலும் உயர் தரங்களை உறுதி செய்தல்',
      'Community': 'சமூகம்',
      'Creating connections that strengthen local communities':
          'உள்ளூர் சமூகங்களை வலுப்படுத்தும் தொடர்புகளை உருவாக்குதல்',
      'Empowerment': 'அதிகாரமளித்தல்',
      'Enabling helpers to build sustainable income streams':
          'நிலையான வருமான ஓடைகளை உருவாக்க உதவியாளர்களுக்கு உதவுதல்',
      'Sign Up': 'பதிவு செய்யுங்கள்',
      'Create your profile and showcase your skills':
          'உங்கள் சுயவிவரத்தை உருவாக்கி உங்கள் திறமைகளை காட்டுங்கள்',
      'Get Verified': 'சரிபார்க்கப்படுங்கள்',
      'Complete verification for trust and safety':
          'நம்பிக்கை மற்றும் பாதுகாப்பிற்காக சரிபார்ப்பை முடிக்கவும்',
      'Browse Jobs': 'வேலைகளைப் பார்க்கவும்',
      'Find opportunities that match your expertise':
          'உங்கள் நிபுணத்துவத்துடன் பொருந்தும் வாய்ப்புகளைக் கண்டறியவும்',
      'Deliver Service': 'சேவையை வழங்கவும்',
      'Provide excellent service to your clients':
          'உங்கள் வாடிக்கையாளர்களுக்கு சிறந்த சேவையை வழங்கவும்',
      'Get Paid': 'பணம் பெறுங்கள்',
      'Receive secure payments for your work':
          'உங்கள் வேலைக்கு பாதுகாப்பான பணம் பெறுங்கள்',
      'App Version': 'பயன்பாட்டு பதிப்பு',

      // Job Detail Page
      'Loading job details...': 'வேலை விவரங்கள் ஏற்றுகிறது...',
      'Failed to load job details': 'வேலை விவரங்களை ஏற்ற முடியவில்லை',
      'Job details': 'வேலை விவரங்கள்',
      'PRIVATE': 'தனிப்பட்ட',
      'PUBLIC': 'பொது',
      'General Services': 'பொது சேவைகள்',
      'Not specified': 'குறிப்பிடப்படவில்லை',
      'PENDING': 'நிலுவையில்',
      'ACCEPTED': 'ஏற்றுக்கொள்ளப்பட்டது',
      'ONGOING': 'நடைபெறுகிறது',
      'COMPLETED': 'முடிந்தது',
      'CANCELLED': 'ரத்து செய்யப்பட்டது',

      // Help & Support
      'Live Chat': 'நேரடி அரட்டை',
      'Get instant help': 'உடனடி உதவி பெறுங்கள்',
      'Call Us': 'எங்களை அழையுங்கள்',
      'Search help topics...': 'உதவி தலைப்புகளைத் தேடுங்கள்...',
      'Getting Started': 'தொடங்குதல்',
      'Job Management': 'வேலை மேலாண்மை',
      'Payment Issues': 'பணம் செலுத்தும் சிக்கல்கள்',
      'Account Settings': 'கணக்கு அமைப்புகள்',
      'Technical Support': 'தொழில்நுட்ப ஆதரவு',
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
