import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/route_guard.dart';

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
import '../pages/helper/helper_8_view_requests_page.dart';
import '../pages/helper/helper_10_activity_pending_page.dart';
import '../pages/helper/helper_13_calendar_page.dart';
import '../pages/helper/helper_19_notification_page.dart';
import '../pages/helper/helper_20_menu_page.dart';
import '../pages/helper/helper_21_profile_tab_page.dart';
import '../pages/helper/helper_22_profile_edit_page.dart';
import '../pages/helper/helper_24_profile_jobs_edit_page.dart';
import '../pages/helper/helper_26_profile_resume_edit_page.dart';
import '../pages/helper/helper_earnings_page.dart';
import '../pages/helper/helper_help_support_page.dart';
import '../pages/helper/helper_about_us_page.dart';
import '../pages/helper/helper_terms_conditions_page.dart';
import '../pages/helper/helper_privacy_policy_page.dart';
import '../pages/helper/helper_helpee_profile_page.dart';
import '../pages/helper/helper_comprehensive_job_detail_page.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) => RouteGuard.guardRoute(context, state),
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Helpee7JobRequestPage(
            isEdit: extra?['isEdit'] ?? false,
            jobData: extra?['jobData'],
          );
        },
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Helpee14HelperProfilePage(
            helperId: extra?['helperId'],
            helperData: extra?['helperData'],
          );
        },
      ),
      GoRoute(
        path: '/helpee/helper-profile-detailed',
        name: 'helpee-helper-profile-detailed',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Helpee14HelperProfilePage(
            helperId: extra?['helperId'],
            helperData: extra?['helperData'],
          );
        },
      ),
      // Helpee Job Detail Routes
      GoRoute(
        path: '/helpee/job-detail/pending',
        name: 'helpee-job-detail-pending',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HelpeeJobDetailPendingPage(
            jobId: extra?['jobId'],
            jobData: extra?['jobData'],
          );
        },
      ),
      GoRoute(
        path: '/helpee/job-detail/ongoing',
        name: 'helpee-job-detail-ongoing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HelpeeJobDetailOngoingPage(
            jobId: extra?['jobId'],
            jobData: extra?['jobData'],
          );
        },
      ),
      GoRoute(
        path: '/helpee/job-detail/completed',
        name: 'helpee-job-detail-completed',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HelpeeJobDetailCompletedPage(
            jobId: extra?['jobId'],
            jobData: extra?['jobData'],
          );
        },
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
      GoRoute(
        path: '/helpee/job-request-edit',
        name: 'helpee-job-request-edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Helpee13JobRequestEditPage(
            jobId: extra?['jobId'],
            jobData: extra?['jobData'],
          );
        },
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
        routes: [
          GoRoute(
            path: 'requests',
            builder: (context, state) => const Helper8ViewRequestsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/helper/view-requests/private',
        name: 'helper-view-requests-private',
        builder: (context, state) =>
            const Helper8ViewRequestsPage(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/helper/view-requests/public',
        name: 'helper-view-requests-public',
        builder: (context, state) =>
            const Helper8ViewRequestsPage(initialTabIndex: 1),
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
        path: '/helper/profile/edit',
        name: 'helper-profile-edit',
        builder: (context, state) => const Helper22ProfileEditPage(),
      ),
      GoRoute(
        path: '/helper/profile/jobs/edit',
        name: 'helper-profile-jobs-edit',
        builder: (context, state) => const Helper24ProfileJobsEditPage(),
      ),
      GoRoute(
        path: '/helper/profile/resume/edit',
        name: 'helper-profile-resume-edit',
        builder: (context, state) => const Helper26ProfileResumeEditPage(),
      ),
      GoRoute(
        path: '/helper/comprehensive-job-detail/:jobId',
        name: 'helper-comprehensive-job-detail',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return HelperComprehensiveJobDetailPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/helper/helpee-profile',
        name: 'helper-helpee-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HelperHelpeeProfilePage(
            helpeeId: extra?['helpeeId'],
            helpeeData: extra?['helpeeData'],
            helpeeStats: extra?['helpeeStats'],
          );
        },
      ),

      GoRoute(
        path: '/helper/earnings',
        name: 'helper-earnings',
        builder: (context, state) => const HelperEarningsPage(),
      ),
      GoRoute(
        path: '/helper/help-support',
        name: 'helper-help-support',
        builder: (context, state) => const HelperHelpSupportPage(),
      ),
      GoRoute(
        path: '/helper/about-us',
        name: 'helper-about-us',
        builder: (context, state) => const HelperAboutUsPage(),
      ),
      GoRoute(
        path: '/helper/terms-conditions',
        name: 'helper-terms-conditions',
        builder: (context, state) => const HelperTermsConditionsPage(),
      ),
      GoRoute(
        path: '/helper/privacy-policy',
        name: 'helper-privacy-policy',
        builder: (context, state) => const HelperPrivacyPolicyPage(),
      ),
    ],
  );
}
