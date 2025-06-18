import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import all page files
import '../pages/common/user_1_start_page.dart';
import '../pages/common/user_2_intro_page_1.dart';
import '../pages/common/user_3_intro_page_2.dart';
import '../pages/common/user_4_intro_page_3.dart';
import '../pages/common/user_5_user_selection_page.dart';

// Helpee pages
import '../pages/helpee/helpee_1_auth_page.dart';
import '../pages/helpee/helpee_2_login_page.dart';
import '../pages/helpee/helpee_3_register_page.dart';
import '../pages/helpee/helpee_4_home_page.dart';
import '../pages/helpee/helpee_5_notification_page.dart';
import '../pages/helpee/helpee_6_menu_page.dart';
import '../pages/helpee/helpee_7_job_request_page.dart';
import '../pages/helpee/helpee_8_calendar_page.dart';
import '../pages/helpee/helpee_9_search_helper_page.dart';
import '../pages/helpee/helpee_10_profile_page.dart';
import '../pages/helpee/helpee_11_profile_edit_page.dart';
import '../pages/helpee/helpee_12_job_request_view_page.dart';
import '../pages/helpee/helpee_13_job_request_edit_page.dart';
import '../pages/helpee/helpee_14_helper_profile_page.dart';
import '../pages/helpee/helpee_15_activity_pending_page.dart';
import '../pages/helpee/helpee_16_activity_ongoing_page.dart';
import '../pages/helpee/helpee_17_activity_completed_page.dart';
import '../pages/helpee/helpee_18_ai_bot_page.dart';
import '../pages/helpee/helpee_19_helper_rating_page.dart';
import '../pages/helpee/helpee_20_about_us_page.dart';
import '../pages/helpee/helpee_22_payment_new_card_page.dart';
import '../pages/helpee/helpee_23_help_support_my_jobs_page.dart';
import '../pages/helpee/helpee_24_help_support_other_options_page.dart';
import '../pages/helpee/helpee_25_job_pending_request_page.dart';
import '../pages/helpee/helpee_26_job_accepted_page.dart';
import '../pages/helpee/helpee_27_job_ongoing_page.dart';
import '../pages/helpee/helpee_28_job_completed_page.dart';

// Helper pages
import '../pages/helper/helper_1_auth_page.dart';
import '../pages/helper/helper_2_login_page.dart';
import '../pages/helper/helper_3_registration_page_1.dart';
import '../pages/helper/helper_7_home_page.dart';
import '../pages/helper/helper_8_view_requests_private_page.dart';
import '../pages/helper/helper_9_view_requests_public_page.dart';
import '../pages/helper/helper_10_activity_pending_page.dart';
import '../pages/helper/helper_11_activity_ongoing_page.dart';
import '../pages/helper/helper_12_activity_completed_page.dart';
import '../pages/helper/helper_13_calendar_page.dart';
import '../pages/helper/helper_14_job_pending_request_page.dart';
import '../pages/helper/helper_15_job_accepted_request_page.dart';
import '../pages/helper/helper_16_job_ongoing_page.dart';
import '../pages/helper/helper_17_job_completed_page.dart';
import '../pages/helper/helper_18_job_request_info_page.dart';
import '../pages/helper/helper_19_notification_page.dart';
import '../pages/helper/helper_20_menu_page.dart';
import '../pages/helper/helper_21_profile_tab_page.dart';
import '../pages/helper/helper_22_profile_edit_page.dart';
import '../pages/helper/helper_23_profile_jobs_tab_page.dart';
import '../pages/helper/helper_24_profile_jobs_edit_page.dart';
import '../pages/helper/helper_25_profile_resume_tab_page.dart';
import '../pages/helper/helper_26_profile_resume_edit_page.dart';
import '../pages/helper/helper_27_helpee_rating_page.dart';
import '../pages/helper/helper_28_job_overview_page.dart';
import '../pages/helper/helper_job_detail_page.dart';
import '../pages/helper/helper_job_detail_simple_pending.dart';
import '../pages/helper/helper_job_detail_simple_ongoing.dart';
import '../pages/helper/helper_job_detail_simple_completed.dart';
import '../pages/helper/helper_helpee_profile_page.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Common User Routes
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const User1StartPage(),
      ),
      GoRoute(
        path: '/intro1',
        name: 'intro1',
        builder: (context, state) => const User2IntroPage1(),
      ),
      GoRoute(
        path: '/intro2',
        name: 'intro2',
        builder: (context, state) => const User3IntroPage2(),
      ),
      GoRoute(
        path: '/intro3',
        name: 'intro3',
        builder: (context, state) => const User4IntroPage3(),
      ),
      GoRoute(
        path: '/user-selection',
        name: 'userSelection',
        builder: (context, state) => const User5UserSelectionPage(),
      ),

      // Helpee Routes
      GoRoute(
        path: '/helpee-auth',
        name: 'helpeeAuth',
        builder: (context, state) => const Helpee1AuthPage(),
      ),
      GoRoute(
        path: '/helpee-login',
        name: 'helpeeLogin',
        builder: (context, state) => const Helpee2LoginPage(),
      ),
      GoRoute(
        path: '/helpee-register',
        name: 'helpeeRegister',
        builder: (context, state) => const Helpee3RegisterPage(),
      ),
      GoRoute(
        path: '/helpee/home',
        name: 'helpeeHome',
        builder: (context, state) => const Helpee4HomePage(),
      ),
      GoRoute(
        path: '/helpee/notifications',
        name: 'helpee-notifications',
        builder: (context, state) => const Helpee5NotificationPage(),
      ),
      GoRoute(
        path: '/helpee/menu',
        name: 'helpee-menu',
        builder: (context, state) => const Helpee6MenuPage(),
      ),
      GoRoute(
        path: '/helpee/job-request',
        name: 'helpee-job-request',
        builder: (context, state) => const Helpee7JobRequestPage(),
      ),
      GoRoute(
        path: '/helpee/calendar',
        name: 'helpee-calendar',
        builder: (context, state) => const Helpee8CalendarPage(),
      ),
      GoRoute(
        path: '/helpee/search-helper',
        name: 'helpee-search-helper',
        builder: (context, state) => const Helpee9SearchHelperPage(),
      ),
      GoRoute(
        path: '/helpee/profile',
        name: 'helpee-profile',
        builder: (context, state) => const Helpee10ProfilePage(),
      ),
      GoRoute(
        path: '/helpee/profile-edit',
        name: 'helpee-profile-edit',
        builder: (context, state) => const Helpee11ProfileEditPage(),
      ),
      GoRoute(
        path: '/helpee/activity/pending',
        name: 'helpee-activity-pending',
        builder: (context, state) => const Helpee15ActivityPendingPage(),
      ),
      GoRoute(
        path: '/helpee/activity/ongoing',
        name: 'helpee-activity-ongoing',
        builder: (context, state) => const Helpee16ActivityOngoingPage(),
      ),
      GoRoute(
        path: '/helpee/activity/completed',
        name: 'helpee-activity-completed',
        builder: (context, state) => const Helpee17ActivityCompletedPage(),
      ),
      GoRoute(
        path: '/helpee/job-request-view',
        name: 'helpee-job-request-view',
        builder: (context, state) => const Helpee12JobRequestViewPage(),
      ),
      GoRoute(
        path: '/helpee/job-request-edit',
        name: 'helpee-job-request-edit',
        builder: (context, state) => const Helpee13JobRequestEditPage(),
      ),
      GoRoute(
        path: '/helpee/helper-profile',
        name: 'helpee-helper-profile',
        builder: (context, state) => const Helpee14HelperProfilePage(),
      ),
      GoRoute(
        path: '/helpee/ai-bot',
        name: 'helpee-ai-bot',
        builder: (context, state) => const Helpee18AIBotPage(),
      ),
      GoRoute(
        path: '/helpee/helper-rating',
        name: 'helpee-helper-rating',
        builder: (context, state) => const Helpee19HelperRatingPage(),
      ),
      GoRoute(
        path: '/helpee/about-us',
        name: 'helpee-about-us',
        builder: (context, state) => const Helpee20AboutUsPage(),
      ),
      GoRoute(
        path: '/helpee/payment-new-card',
        name: 'helpee-payment-new-card',
        builder: (context, state) => const Helpee22PaymentNewCardPage(),
      ),
      GoRoute(
        path: '/helpee/help-support-my-jobs',
        name: 'helpee-help-support-my-jobs',
        builder: (context, state) => const Helpee23HelpSupportMyJobsPage(),
      ),
      GoRoute(
        path: '/helpee/help-support-other-options',
        name: 'helpee-help-support-other-options',
        builder: (context, state) =>
            const Helpee24HelpSupportOtherOptionsPage(),
      ),
      GoRoute(
        path: '/helpee/job-pending-request',
        name: 'helpee-job-pending-request',
        builder: (context, state) => const Helpee25JobPendingRequestPage(),
      ),
      GoRoute(
        path: '/helpee/job-accepted',
        name: 'helpee-job-accepted',
        builder: (context, state) => const Helpee26JobAcceptedPage(),
      ),
      GoRoute(
        path: '/helpee/job-ongoing',
        name: 'helpee-job-ongoing',
        builder: (context, state) => const Helpee27JobOngoingPage(),
      ),
      GoRoute(
        path: '/helpee/job-completed',
        name: 'helpee-job-completed',
        builder: (context, state) => const Helpee28JobCompletedPage(),
      ),

      // Helper Routes
      GoRoute(
        path: '/helper-auth',
        name: 'helperAuth',
        builder: (context, state) => const Helper1AuthPage(),
      ),
      GoRoute(
        path: '/helper-login',
        name: 'helperLogin',
        builder: (context, state) => const Helper2LoginPage(),
      ),
      GoRoute(
        path: '/helper-register',
        name: 'helperRegister',
        builder: (context, state) => const Helper3RegistrationPage1(),
      ),
      GoRoute(
        path: '/helper/home',
        name: 'helperHome',
        builder: (context, state) => const Helper7HomePage(),
      ),
      GoRoute(
        path: '/helper/view-requests/private',
        name: 'helper-view-requests-private',
        builder: (context, state) => const Helper8ViewRequestsPrivatePage(),
      ),
      GoRoute(
        path: '/helper/view-requests/public',
        name: 'helper-view-requests-public',
        builder: (context, state) => const Helper9ViewRequestsPublicPage(),
      ),
      GoRoute(
        path: '/helper/calendar',
        name: 'helper-calendar',
        builder: (context, state) => const Helper13CalendarPage(),
      ),
      GoRoute(
        path: '/helper/job-pending-request',
        name: 'helper-job-pending-request',
        builder: (context, state) => const Helper14JobPendingRequestPage(),
      ),
      GoRoute(
        path: '/helper/job-accepted-request',
        name: 'helper-job-accepted-request',
        builder: (context, state) => const Helper15JobAcceptedRequestPage(),
      ),
      GoRoute(
        path: '/helper/job-ongoing',
        name: 'helper-job-ongoing',
        builder: (context, state) => const Helper16JobOngoingPage(),
      ),
      GoRoute(
        path: '/helper/job-completed',
        name: 'helper-job-completed',
        builder: (context, state) => const Helper17JobCompletedPage(),
      ),
      GoRoute(
        path: '/helper/job-request-info',
        name: 'helper-job-request-info',
        builder: (context, state) => const Helper18JobRequestInfoPage(),
      ),
      GoRoute(
        path: '/helper/notifications',
        name: 'helper-notifications',
        builder: (context, state) => const Helper19NotificationPage(),
      ),
      GoRoute(
        path: '/helper/menu',
        name: 'helper-menu',
        builder: (context, state) => const Helper20MenuPage(),
      ),
      GoRoute(
        path: '/helper/activity/pending',
        name: 'helper-activity-pending',
        builder: (context, state) =>
            const Helper10ActivityPendingPage(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/helper/activity/ongoing',
        name: 'helper-activity-ongoing',
        builder: (context, state) =>
            const Helper10ActivityPendingPage(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/helper/activity/completed',
        name: 'helper-activity-completed',
        builder: (context, state) =>
            const Helper10ActivityPendingPage(initialTabIndex: 2),
      ),
      GoRoute(
        path: '/helper/profile',
        name: 'helper-profile',
        builder: (context, state) => const Helper21ProfileTabPage(),
      ),
      GoRoute(
        path: '/helper/profile/edit',
        name: 'helper-profile-edit',
        builder: (context, state) => const Helper22ProfileEditPage(),
      ),
      GoRoute(
        path: '/helper/profile/jobs',
        name: 'helper-profile-jobs',
        builder: (context, state) => const Helper23ProfileJobsTabPage(),
      ),
      GoRoute(
        path: '/helper/profile/jobs/edit',
        name: 'helper-profile-jobs-edit',
        builder: (context, state) => const Helper24ProfileJobsEditPage(),
      ),
      GoRoute(
        path: '/helper/profile/resume',
        name: 'helper-profile-resume',
        builder: (context, state) => const Helper25ProfileResumeTabPage(),
      ),
      GoRoute(
        path: '/helper/profile/resume/edit',
        name: 'helper-profile-resume-edit',
        builder: (context, state) => const Helper26ProfileResumeEditPage(),
      ),
      GoRoute(
        path: '/helper/helpee-rating',
        name: 'helper-helpee-rating',
        builder: (context, state) => const Helper27HelpeeRatingPage(),
      ),
      GoRoute(
        path: '/helper/job-overview',
        name: 'helper-job-overview',
        builder: (context, state) => const Helper28JobOverviewPage(),
      ),
      GoRoute(
        path: '/helper/job-detail',
        name: 'helper-job-detail',
        builder: (context, state) => const HelperJobDetailPage(),
      ),
      GoRoute(
        path: '/helper/job-detail-simple/pending',
        builder: (context, state) => const HelperJobDetailSimplePendingPage(),
      ),
      GoRoute(
        path: '/helper/job-detail-simple/ongoing',
        builder: (context, state) => const HelperJobDetailSimpleOngoingPage(),
      ),
      GoRoute(
        path: '/helper/job-detail-simple/completed',
        builder: (context, state) => const HelperJobDetailSimpleCompletedPage(),
      ),
      GoRoute(
        path: '/helper/helpee-profile',
        builder: (context, state) => const HelperHelpeeProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );

  // Navigation helper methods
  static void goToIntro1() => router.go('/intro1');
  static void goToIntro2() => router.go('/intro2');
  static void goToIntro3() => router.go('/intro3');
  static void goToUserSelection() => router.go('/user-selection');

  static void goToHelpeeAuth() => router.go('/helpee-auth');
  static void goToHelpeeLogin() => router.go('/helpee-login');
  static void goToHelpeeRegister() => router.go('/helpee-register');
  static void goToHelpeeHome() => router.go('/helpee/home');

  static void goToHelperAuth() => router.go('/helper-auth');
  static void goToHelperLogin() => router.go('/helper-login');
  static void goToHelperRegister() => router.go('/helper-register');
  static void goToHelperHome() => router.go('/helper/home');

  static void goBack() => router.pop();
}
