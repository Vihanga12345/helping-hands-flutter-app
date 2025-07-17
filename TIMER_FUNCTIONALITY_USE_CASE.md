# HELPING HANDS JOB TIMER FUNCTIONALITY - SIMPLIFIED USE CASE

## Overview
This document outlines the simplified timer functionality for the Helping Hands app, where only helpers see and control the timer, while helpees see a simple "Job Ongoing" indicator.

---

## 1. USER TYPES AND ROLES

### 1.1 Helper (Timer Controller)
- **Can control timer**: Start, Pause, Resume, Complete
- **Sees**: Real-time timer display with controls in job detail page
- **Timer persistence**: Timer runs in background across page navigation
- **Location**: Job detail page only (NOT in activity lists)
- **Responsibilities**: Track actual work time using timer controls

### 1.2 Helpee (Observer)
- **Cannot control timer**: No timer controls visible
- **Sees**: "Job Ongoing" indicator when job is in progress
- **Location**: Job detail page shows status indicator
- **Responsibilities**: Wait for job completion notification

---

## 2. SIMPLIFIED TIMER LIFECYCLE

### 2.1 Job Status Progression
```
pending → accepted → in_progress (when timer starts) → completed
```

### 2.2 Timer State Machine (Helper Only)
```
not_started → running → paused ⟷ running → completed
```

---

## 3. DETAILED USER JOURNEY

### Phase 1: Job Acceptance
**Who**: Helper
**Action**: Accept job
**Result**: 
- Job status changes to `accepted`
- Timer becomes available to helper (not started)
- Helpee sees job in "ongoing" tab

### Phase 2: Starting Work (Helper Only)
**Who**: Helper  
**When**: Helper arrives and begins work
**Action**: Click "Start Timer" button in job detail page
**What Happens**:

#### 2.1 Database Updates:
```sql
- jobs.timer_status = 'running'
- jobs.is_timer_running = true
- jobs.session_start_time = NOW()
- jobs.status = 'in_progress'
- jobs.updated_at = NOW()
```

#### 2.2 Timer Behavior:
- **Helper sees**: Timer starts counting (00:00:01, 00:00:02...)
- **Timer persists**: Continues running when helper navigates to other pages
- **Background operation**: Timer runs in app background service
- **Helpee sees**: "Job Ongoing" indicator (no timer display)

### Phase 3: Work Pause (Helper Only)
**Who**: Helper  
**When**: Helper needs a break
**Action**: Click "Pause" button
**What Happens**:

#### 3.1 Database Updates:
```sql
-- Save current session duration
session_duration = NOW() - session_start_time (in seconds)

-- Update cumulative time
UPDATE jobs SET
  cumulative_time_seconds = cumulative_time_seconds + session_duration,
  timer_status = 'paused',
  is_timer_running = false,
  session_pause_time = NOW()
```

#### 3.2 Display Updates:
- **Helper sees**: Timer stops, shows "PAUSED" status with accumulated time
- **Helpee sees**: "Job Ongoing" indicator remains (no change)

### Phase 4: Work Resume (Helper Only)
**Who**: Helper  
**Action**: Click "Resume" button
**What Happens**:

#### 4.1 Database Updates:
```sql
UPDATE jobs SET
  timer_status = 'running',
  session_start_time = NOW(),
  is_timer_running = true
```

#### 4.2 Timer Behavior:
- **Helper sees**: Timer resumes from accumulated time
- **Background**: Timer continues across page navigation
- **Helpee sees**: "Job Ongoing" indicator continues

### Phase 5: Job Completion (Helper Only)
**Who**: Helper  
**When**: Work is finished
**Action**: Click "Complete Job" button
**What Happens**:

#### 5.1 Final Time Calculation:
```sql
-- If timer is running, add current session
IF timer_status = 'running' THEN
  session_duration = NOW() - session_start_time
  cumulative_time_seconds = cumulative_time_seconds + session_duration
END IF

-- Calculate payment
total_hours = cumulative_time_seconds / 3600.0
calculated_amount = total_hours * hourly_rate

-- Minimum 1 hour charge
IF calculated_amount < hourly_rate THEN
  calculated_amount = hourly_rate
END IF
```

#### 5.2 Job Completion:
```sql
UPDATE jobs SET
  status = 'completed',
  timer_status = 'completed',
  is_timer_running = false,
  completed_at = NOW(),
  final_amount = calculated_amount,
  payment_amount_calculated = calculated_amount
```

#### 5.3 Payment Popup:
- **Helpee receives**: Payment confirmation popup
- **Shows**: "Please pay LKR X in cash to helper"
- **Amount**: Calculated based on total timer duration

---

## 4. USER INTERFACE DESIGN

### 4.1 Helper Timer Widget (Job Detail Page Only)
```
┌─────────────────────────────────────┐
│ 🔵 Job Timer          [ACTIVE]     │
├─────────────────────────────────────┤
│           02:35:42                  │
│                                     │
│  Hours Worked    │  Estimated Cost  │
│      2.60h       │   LKR 130.00     │
├─────────────────────────────────────┤
│  [Pause]  [Complete Job]            │
└─────────────────────────────────────┘
```

### 4.2 Helpee Status Indicator (Job Detail Page)
```
┌─────────────────────────────────────┐
│ 🟢 Job Status                      │
├─────────────────────────────────────┤
│                                     │
│        Job is Ongoing               │
│                                     │
│    Your helper is currently         │
│        working on this job          │
│                                     │
│  ⏳ Please wait for completion...   │
│                                     │
└─────────────────────────────────────┘
```

---

## 5. TECHNICAL IMPLEMENTATION

### 5.1 Background Timer Service
```dart
class BackgroundJobTimerService {
  static Timer? _backgroundTimer;
  static String? _activeJobId;
  static DateTime? _sessionStartTime;
  static int _cumulativeSeconds = 0;
  
  // Persists across page navigation
  static void startTimer(String jobId) {
    // Start background timer that updates every second
    // Save state to local storage for app restart recovery
  }
  
  static void pauseTimer() {
    // Stop background timer, save accumulated time to database
  }
  
  static void resumeTimer() {
    // Restart background timer from accumulated time
  }
}
```

### 5.2 Helper Job Detail Page Integration
```dart
// Only show timer widget for helper
if (isHelper && ['accepted', 'in_progress'].contains(jobStatus)) {
  HelperJobTimerWidget(
    jobId: jobId,
    onTimerAction: (action) {
      // Handle timer actions without page refresh
    },
  ),
}
```

### 5.3 Helpee Job Detail Page Integration
```dart
// Show simple status indicator for helpee
if (!isHelper && jobStatus == 'in_progress') {
  JobOngoingIndicator(
    jobTitle: jobTitle,
    helperName: helperName,
  ),
}
```

---

## 6. DATABASE SCHEMA (Simplified)

### 6.1 Required Fields
```sql
-- Jobs Table
timer_status VARCHAR DEFAULT 'not_started'
is_timer_running BOOLEAN DEFAULT false
cumulative_time_seconds INTEGER DEFAULT 0
session_start_time TIMESTAMP
final_amount DECIMAL(10,2)
hourly_rate DECIMAL(10,2)
```

### 6.2 No Real-time Sync Required
- No complex real-time listeners
- No cross-user timer synchronization
- Simple database updates on timer actions

---

## 7. BENEFITS OF SIMPLIFIED APPROACH

### 7.1 Technical Benefits
- **No sync complexity**: Eliminates real-time synchronization issues
- **Better performance**: No constant database polling
- **Simpler code**: Easier to maintain and debug
- **Fewer edge cases**: Less chance of timer sync failures

### 7.2 User Experience Benefits
- **Helper focused**: Timer controls where they're needed
- **Clear separation**: Helper tracks time, helpee waits for completion
- **No confusion**: Helpee doesn't see timer they can't control
- **Reliable operation**: Timer works consistently across app usage

---

## 8. TESTING SCENARIOS

### 8.1 Helper Timer Testing
1. Start timer → Timer begins counting
2. Navigate between pages → Timer continues in background
3. Pause timer → Time saved, timer stops
4. Resume timer → Timer continues from saved time
5. Complete job → Final time calculated, payment triggered

### 8.2 Helpee Experience Testing
1. Job accepted → See "ongoing" status
2. Timer started by helper → See "Job Ongoing" indicator
3. Job completed → Receive payment popup

### 8.3 Edge Case Testing
1. App restart with running timer → Timer state recovered
2. Network interruption → Timer continues locally
3. Multiple pause/resume cycles → Accurate total time

---

## 9. SUCCESS CRITERIA

### 9.1 Functional Requirements
- ✅ Helper can start/pause/resume timer
- ✅ Timer persists across page navigation
- ✅ Accurate time tracking for payment calculation
- ✅ Helpee sees appropriate status indicators
- ✅ Payment calculation based on timer duration

### 9.2 User Experience Requirements
- ✅ Simple, intuitive timer controls for helper
- ✅ Clear job status for helpee
- ✅ No unnecessary complexity or sync issues
- ✅ Reliable timer operation

---

**This simplified approach provides reliable timer functionality focused on the helper's needs while giving helpees clear status information without unnecessary complexity.** 