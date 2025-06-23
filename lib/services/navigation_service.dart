import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Common User Pages
import '../pages/common/user_1_start_page.dart';
import '../pages/common/user_2_intro_page_1.dart';
import '../pages/common/user_3_intro_page_2.dart';
import '../pages/common/user_4_intro_page_3.dart';
import '../pages/common/user_5_user_selection_page.dart';

// Helpee Pages
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
import '../pages/helpee/helpee_21_payment_page.dart';
import '../pages/helpee/helpee_job_detail_pending.dart';
import '../pages/helpee/helpee_job_detail_ongoing.dart';
import '../pages/helpee/helpee_job_detail_completed.dart';
import '../pages/helpee/helpee_23_help_support_my_jobs_page.dart';

// Helper Pages
import '../pages/helper/helper_1_auth_page.dart';
import '../pages/helper/helper_2_login_page.dart';
import '../pages/helper/helper_3_registration_page_1.dart';
import '../pages/helper/helper_7_home_page.dart';
import '../pages/helper/helper_8_view_requests_private_page.dart';
import '../pages/helper/helper_9_view_requests_public_page.dart';
import '../pages/helper/helper_10_activity_pending_page.dart';
import '../pages/helper/helper_13_calendar_page.dart';
import '../pages/helper/helper_19_notification_page.dart';
import '../pages/helper/helper_20_menu_page.dart';
import '../pages/helper/helper_21_profile_tab_page.dart';
import '../pages/helper/helper_job_detail_page.dart';
import '../pages/helper/helper_helpee_profile_page.dart';
import '../pages/helper/helper_job_detail_pending.dart';
import '../pages/helper/helper_job_detail_ongoing.dart';
import '../pages/helper/helper_job_detail_completed.dart';

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
        path: '/helpee/helper-profile',
        name: 'helpee-helper-profile',
        builder: (context, state) => const Helpee14HelperProfilePage(),
      ),
      // Helpee Job Detail Routes
      GoRoute(
        path: '/helpee/job-detail/pending',
        name: 'helpee-job-detail-pending',
        builder: (context, state) => const HelpeeJobDetailPendingPage(),
      ),
      GoRoute(
        path: '/helpee/job-detail/ongoing',
        name: 'helpee-job-detail-ongoing',
        builder: (context, state) => const HelpeeJobDetailOngoingPage(),
      ),
      GoRoute(
        path: '/helpee/job-detail/completed',
        name: 'helpee-job-detail-completed',
        builder: (context, state) => const HelpeeJobDetailCompletedPage(),
      ),
      GoRoute(
        path: '/helpee/about-us',
        name: 'helpee-about-us',
        builder: (context, state) => const Helpee20AboutUsPage(),
      ),
      GoRoute(
        path: '/helpee/payments',
        name: 'helpee-payments',
        builder: (context, state) => const Helpee21PaymentPage(),
      ),
      GoRoute(
        path: '/helpee/help-support',
        name: 'helpee-help-support',
        builder: (context, state) => const Helpee23HelpSupportMyJobsPage(),
      ),
      GoRoute(
        path: '/helpee/profile/edit',
        name: 'helpee-profile-edit',
        builder: (context, state) => const Helpee11ProfileEditPage(),
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
        path: '/helper/activity/pending',
        name: 'helper-activity-pending',
        builder: (context, state) =>
            const HelperActivityPendingPage(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/helper/activity/ongoing',
        name: 'helper-activity-ongoing',
        builder: (context, state) =>
            const HelperActivityPendingPage(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/helper/activity/completed',
        name: 'helper-activity-completed',
        builder: (context, state) =>
            const HelperActivityPendingPage(initialTabIndex: 2),
      ),
      GoRoute(
        path: '/helper/calendar',
        name: 'helper-calendar',
        builder: (context, state) => const Helper13CalendarPage(),
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
        path: '/helper/profile',
        name: 'helper-profile',
        builder: (context, state) => const Helper21ProfileTabPage(),
      ),
      GoRoute(
        path: '/helper/comprehensive-job-detail',
        name: 'helper-comprehensive-job-detail',
        builder: (context, state) => const HelperJobDetailPage(),
      ),
      GoRoute(
        path: '/helper/helpee-profile',
        name: 'helper-helpee-profile',
        builder: (context, state) => const HelperHelpeeProfilePage(),
      ),
      // Helper Job Detail Routes
      GoRoute(
        path: '/helper/job-detail/pending',
        name: 'helper-job-detail-pending',
        builder: (context, state) => const HelperJobDetailPendingPage(),
      ),
      GoRoute(
        path: '/helper/job-detail/ongoing',
        name: 'helper-job-detail-ongoing',
        builder: (context, state) => const HelperJobDetailOngoingPage(),
      ),
      GoRoute(
        path: '/helper/job-detail/completed',
        name: 'helper-job-detail-completed',
        builder: (context, state) => const HelperJobDetailCompletedPage(),
      ),
    ],
  );
}
