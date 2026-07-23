# Student Status Checkup System (SSCS)

A student management system with Flutter mobile app, React admin portal, and Supabase backend.

## Tech Stack

- **Mobile** — Flutter + Riverpod + GoRouter
- **Web** — React + Vite + TypeScript + TailwindCSS
- **Backend** — Supabase (PostgreSQL, Auth, Storage, Edge Functions)

## Roles

- Administrator
- Teacher
- Parent

## Project Structure

```
student-status-checkup-system/
│
├── mobile/                          # Flutter app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_constants.dart
│   │   │   │   ├── api_constants.dart
│   │   │   │   └── storage_keys.dart
│   │   │   ├── theme/
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   └── app_text_styles.dart
│   │   │   ├── router/
│   │   │   │   └── app_router.dart
│   │   │   ├── services/
│   │   │   │   ├── supabase_service.dart
│   │   │   │   └── notification_service.dart
│   │   │   ├── utils/
│   │   │   │   ├── validators.dart
│   │   │   │   └── helpers.dart
│   │   │   └── widgets/
│   │   │       ├── loading_widget.dart
│   │   │       ├── empty_widget.dart
│   │   │       └── error_widget.dart
│   │   │
│   │   ├── models/
│   │   │   ├── profile_model.dart
│   │   │   ├── student_model.dart
│   │   │   ├── teacher_model.dart
│   │   │   ├── parent_model.dart
│   │   │   ├── class_model.dart
│   │   │   ├── academic_year_model.dart
│   │   │   ├── subject_model.dart
│   │   │   ├── attendance_model.dart
│   │   │   ├── result_model.dart
│   │   │   ├── activity_model.dart
│   │   │   ├── announcement_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── conversation_model.dart
│   │   │   ├── notification_model.dart
│   │   │   └── device_token_model.dart
│   │   │
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── auth_page.dart
│   │   │   │   ├── auth_provider.dart
│   │   │   │   ├── auth_service.dart
│   │   │   │   ├── auth_model.dart
│   │   │   │   └── auth_repository.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_page.dart
│   │   │   │   ├── dashboard_provider.dart
│   │   │   │   ├── dashboard_service.dart
│   │   │   │   ├── dashboard_model.dart
│   │   │   │   └── dashboard_repository.dart
│   │   │   ├── students/
│   │   │   │   ├── students_page.dart
│   │   │   │   ├── students_provider.dart
│   │   │   │   ├── students_service.dart
│   │   │   │   ├── students_model.dart
│   │   │   │   └── students_repository.dart
│   │   │   ├── attendance/
│   │   │   │   ├── attendance_page.dart
│   │   │   │   ├── attendance_provider.dart
│   │   │   │   ├── attendance_service.dart
│   │   │   │   ├── attendance_model.dart
│   │   │   │   └── attendance_repository.dart
│   │   │   ├── results/
│   │   │   │   ├── results_page.dart
│   │   │   │   ├── results_provider.dart
│   │   │   │   ├── results_service.dart
│   │   │   │   ├── results_model.dart
│   │   │   │   └── results_repository.dart
│   │   │   ├── activities/
│   │   │   │   ├── activities_page.dart
│   │   │   │   ├── activities_provider.dart
│   │   │   │   ├── activities_service.dart
│   │   │   │   ├── activities_model.dart
│   │   │   │   └── activities_repository.dart
│   │   │   ├── messages/
│   │   │   │   ├── messages_page.dart
│   │   │   │   ├── messages_provider.dart
│   │   │   │   ├── messages_service.dart
│   │   │   │   ├── messages_model.dart
│   │   │   │   └── messages_repository.dart
│   │   │   ├── notifications/
│   │   │   │   ├── notifications_page.dart
│   │   │   │   ├── notifications_provider.dart
│   │   │   │   ├── notifications_service.dart
│   │   │   │   ├── notifications_model.dart
│   │   │   │   └── notifications_repository.dart
│   │   │   ├── announcements/
│   │   │   │   ├── announcements_page.dart
│   │   │   │   ├── announcements_provider.dart
│   │   │   │   ├── announcements_service.dart
│   │   │   │   ├── announcements_model.dart
│   │   │   │   └── announcements_repository.dart
│   │   │   └── settings/
│   │   │       ├── settings_page.dart
│   │   │       ├── settings_provider.dart
│   │   │       ├── settings_service.dart
│   │   │       ├── settings_model.dart
│   │   │       └── settings_repository.dart
│   │   │
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── theme_provider.dart
│   │   │   └── role_provider.dart
│   │   │
│   │   ├── supabase/
│   │   │   ├── supabase_client.dart
│   │   │   └── supabase_tables.dart
│   │   │
│   │   └── main.dart
│   │
│   ├── test/
│   │   └── widget_test.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
├── web/                             # React admin portal
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Layout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   ├── DataTable.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Select.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Spinner.tsx
│   │   │   ├── EmptyState.tsx
│   │   │   ├── ErrorMessage.tsx
│   │   │   ├── Breadcrumb.tsx
│   │   │   └── Pagination.tsx
│   │   │
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   └── NotFoundPage.tsx
│   │   │
│   │   ├── features/
│   │   │   ├── students/
│   │   │   │   ├── StudentListPage.tsx
│   │   │   │   ├── StudentDetailPage.tsx
│   │   │   │   ├── StudentFormPage.tsx
│   │   │   │   ├── studentService.ts
│   │   │   │   ├── useStudents.ts
│   │   │   │   └── studentTypes.ts
│   │   │   ├── teachers/
│   │   │   │   ├── TeacherListPage.tsx
│   │   │   │   ├── TeacherDetailPage.tsx
│   │   │   │   ├── TeacherFormPage.tsx
│   │   │   │   ├── teacherService.ts
│   │   │   │   ├── useTeachers.ts
│   │   │   │   └── teacherTypes.ts
│   │   │   ├── parents/
│   │   │   │   ├── ParentListPage.tsx
│   │   │   │   ├── ParentDetailPage.tsx
│   │   │   │   ├── ParentFormPage.tsx
│   │   │   │   ├── parentService.ts
│   │   │   │   ├── useParents.ts
│   │   │   │   └── parentTypes.ts
│   │   │   ├── attendance/
│   │   │   │   ├── AttendancePage.tsx
│   │   │   │   ├── attendanceService.ts
│   │   │   │   ├── useAttendance.ts
│   │   │   │   └── attendanceTypes.ts
│   │   │   ├── results/
│   │   │   │   ├── ResultsPage.tsx
│   │   │   │   ├── resultsService.ts
│   │   │   │   ├── useResults.ts
│   │   │   │   └── resultsTypes.ts
│   │   │   └── dashboard/
│   │   │       ├── DashboardPage.tsx
│   │   │       ├── dashboardService.ts
│   │   │       ├── useDashboard.ts
│   │   │       └── dashboardTypes.ts
│   │   │
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useSupabase.ts
│   │   │   ├── useDebounce.ts
│   │   │   └── usePagination.ts
│   │   │
│   │   ├── services/
│   │   │   ├── authService.ts
│   │   │   └── api.ts
│   │   │
│   │   ├── types/
│   │   │   └── index.ts
│   │   │
│   │   ├── utils/
│   │   │   ├── constants.ts
│   │   │   ├── helpers.ts
│   │   │   └── formatters.ts
│   │   │
│   │   ├── supabase/
│   │   │   └── client.ts
│   │   │
│   │   ├── router/
│   │   │   └── index.tsx
│   │   │
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   ├── index.css
│   │   └── vite-env.d.ts
│   │
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── tsconfig.app.json
│   ├── tsconfig.node.json
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   ├── index.html
│   └── .env.example
│
├── supabase/                        # Backend
│   ├── config.toml
│   ├── README.md
│   ├── migrations/
│   │   ├── 001_create_tables.sql
│   │   ├── 002_create_rls_policies.sql
│   │   ├── 003_create_functions.sql
│   │   └── 004_create_indexes.sql
│   ├── seed/
│   │   └── seed.sql
│   ├── functions/
│   │   ├── send-notification/
│   │   │   └── index.ts
│   │   ├── get-dashboard-stats/
│   │   │   └── index.ts
│   │   ├── manage-attendance/
│   │   │   └── index.ts
│   │   └── send-message/
│   │       └── index.ts
│   └── storage/
│       ├── avatars/
│       │   └── README.md
│       └── documents/
│           └── README.md
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── README.md
├── .gitignore
├── .env.example
└── docker-compose.yml
```

## Database Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles (linked to Supabase Auth) |
| `students` | Student records |
| `parent_students` | Parent-child relationships |
| `teachers` | Teacher records |
| `classes` | Class groups |
| `academic_years` | School years / terms |
| `teacher_subjects` | Teacher-to-subject assignments |
| `student_enrollments` | Student-to-class-year enrollments |
| `attendance` | Daily attendance records |
| `results` | Academic results / grades |
| `activities` | Extracurricular activities |
| `announcements` | System announcements |
| `announcement_reads` | Read status per user |
| `conversations` | Chat threads |
| `messages` | Chat messages |
| `notifications` | Push notification records |
| `device_tokens` | FCM device tokens |
| `audit_logs` | Admin action logs |

## Getting Started

### Prerequisites
- Flutter 3.24+
- Node 18+
- Supabase CLI
- Firebase project (for push notifications)

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

### Web
```bash
cd web
npm install
npm run dev
```

### Supabase
```bash
supabase init
supabase db push
supabase functions deploy
```
