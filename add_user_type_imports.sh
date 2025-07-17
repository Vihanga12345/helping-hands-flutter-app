#!/bin/bash

# List of files that need the import
files=(
  "lib/pages/helpee/helpee_7_job_request_page.dart"
  "lib/pages/helper/helper_7_home_page.dart"
  "lib/pages/helper/helper_8_view_requests_page.dart"
  "lib/pages/helpee/helpee_4_home_page.dart"
  "lib/pages/helpee/helpee_5_notification_page.dart"
  "lib/pages/helpee/helpee_6_menu_page.dart"
  "lib/pages/helpee/helpee_8_calendar_page.dart"
  "lib/pages/helpee/helpee_9_search_helper_page.dart"
  "lib/pages/helpee/helpee_10_profile_page.dart"
  "lib/pages/helpee/helpee_12_job_request_view_page.dart"
  "lib/pages/helpee/helpee_13_job_request_edit_page.dart"
  "lib/pages/helpee/helpee_14_helper_profile_page.dart"
  "lib/pages/helpee/helpee_15_activity_pending_page.dart"
  "lib/pages/helpee/helpee_16_activity_ongoing_page.dart"
  "lib/pages/helpee/helpee_17_activity_completed_page.dart"
  "lib/pages/helpee/helpee_18_ai_bot_page.dart"
  "lib/pages/helpee/helpee_19_helper_rating_page.dart"
  "lib/pages/helpee/helpee_20_about_us_page.dart"
  "lib/pages/helpee/helpee_21_payment_page.dart"
  "lib/pages/helpee/helpee_job_detail_pending.dart"
  "lib/pages/helpee/helpee_job_detail_ongoing.dart"
  "lib/pages/helpee/helpee_job_detail_completed.dart"
  "lib/pages/helpee/helpee_23_help_support_my_jobs_page.dart"
  "lib/pages/helper/helper_10_activity_pending_page.dart"
  "lib/pages/helper/helper_13_calendar_page.dart"
  "lib/pages/helper/helper_19_notification_page.dart"
  "lib/pages/helper/helper_20_menu_page.dart"
  "lib/pages/helper/helper_21_profile_tab_page.dart"
  "lib/pages/helper/helper_22_profile_edit_page.dart"
  "lib/pages/helper/helper_24_profile_jobs_edit_page.dart"
  "lib/pages/helper/helper_26_profile_resume_edit_page.dart"
  "lib/pages/helper/helper_earnings_page.dart"
  "lib/pages/helper/helper_help_support_page.dart"
  "lib/pages/helper/helper_about_us_page.dart"
  "lib/pages/helper/helper_terms_conditions_page.dart"
  "lib/pages/helper/helper_privacy_policy_page.dart"
  "lib/pages/helper/helper_helpee_profile_page.dart"
  "lib/pages/helper/helper_comprehensive_job_detail_page.dart"
)

# Add import statement to each file
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    # Check if import already exists
    if ! grep -q "import '.*models/user_type.dart';" "$file"; then
      # Add import after the first import statement
      sed -i '1a import '\''../../models/user_type.dart'\'';' "$file"
      echo "Added import to $file"
    else
      echo "Import already exists in $file"
    fi
  else
    echo "File not found: $file"
  fi
done 