import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom'
import { AuthProvider } from '@/contexts/AuthContext'
import LoginPage from '@/pages/LoginPage'
import NotFoundPage from '@/pages/NotFoundPage'
import Layout from '@/components/Layout'
import DashboardPage from '@/features/dashboard/DashboardPage'
import StudentListPage from '@/features/students/StudentListPage'
import StudentDetailPage from '@/features/students/StudentDetailPage'
import StudentFormPage from '@/features/students/StudentFormPage'
import TeacherListPage from '@/features/teachers/TeacherListPage'
import TeacherDetailPage from '@/features/teachers/TeacherDetailPage'
import TeacherFormPage from '@/features/teachers/TeacherFormPage'
import ParentListPage from '@/features/parents/ParentListPage'
import ParentDetailPage from '@/features/parents/ParentDetailPage'
import ParentFormPage from '@/features/parents/ParentFormPage'
import AcademicYearListPage from '@/features/academic-years/AcademicYearListPage'
import AcademicYearFormPage from '@/features/academic-years/AcademicYearFormPage'
import ClassListPage from '@/features/classes/ClassListPage'
import ClassFormPage from '@/features/classes/ClassFormPage'
import ClassDetailPage from '@/features/classes/ClassDetailPage'
import SubjectListPage from '@/features/subjects/SubjectListPage'
import SubjectDetailPage from '@/features/subjects/SubjectDetailPage'
import SubjectFormPage from '@/features/subjects/SubjectFormPage'
import TeacherAssignmentListPage from '@/features/teacher-assignments/TeacherAssignmentListPage'
import TeacherAssignmentFormPage from '@/features/teacher-assignments/TeacherAssignmentFormPage'
import StudentEnrollmentListPage from '@/features/student-enrollments/StudentEnrollmentListPage'
import StudentEnrollmentFormPage from '@/features/student-enrollments/StudentEnrollmentFormPage'
import AttendancePage from '@/features/attendance/AttendancePage'
import AttendanceMarkPage from '@/features/attendance/AttendanceMarkPage'
import ResultsPage from '@/features/results/ResultsPage'
import ResultFormPage from '@/features/results/ResultFormPage'
import AnnouncementListPage from '@/features/announcements/AnnouncementListPage'
import AnnouncementFormPage from '@/features/announcements/AnnouncementFormPage'
import { AuthGuard } from '@/components/AuthGuard'

export const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <AuthProvider>
        <Outlet />
      </AuthProvider>
    ),
    children: [
      {
        path: 'login',
        element: <LoginPage />,
      },
      {
        path: 'reset-password',
        element: <div className="p-8 text-center">Password reset page</div>,
      },
      {
        path: '/',
        element: (
          <AuthGuard>
            <Layout />
          </AuthGuard>
        ),
        children: [
          {
            index: true,
            element: <Navigate to="/dashboard" replace />,
          },
          {
            path: 'dashboard',
            element: <DashboardPage />,
          },
          // Students
          {
            path: 'students',
            element: <StudentListPage />,
          },
          {
            path: 'students/new',
            element: <StudentFormPage />,
          },
          {
            path: 'students/:id',
            element: <StudentDetailPage />,
          },
          {
            path: 'students/:id/edit',
            element: <StudentFormPage />,
          },
          // Teachers
          {
            path: 'teachers',
            element: <TeacherListPage />,
          },
          {
            path: 'teachers/new',
            element: <TeacherFormPage />,
          },
          {
            path: 'teachers/:id',
            element: <TeacherDetailPage />,
          },
          {
            path: 'teachers/:id/edit',
            element: <TeacherFormPage />,
          },
          // Parents
          {
            path: 'parents',
            element: <ParentListPage />,
          },
          {
            path: 'parents/new',
            element: <ParentFormPage />,
          },
          {
            path: 'parents/:id',
            element: <ParentDetailPage />,
          },
          {
            path: 'parents/:id/edit',
            element: <ParentFormPage />,
          },
          // Academic Years
          {
            path: 'academic-years',
            element: <AcademicYearListPage />,
          },
          {
            path: 'academic-years/new',
            element: <AcademicYearFormPage />,
          },
          {
            path: 'academic-years/:id/edit',
            element: <AcademicYearFormPage />,
          },
          // Classes
          {
            path: 'classes',
            element: <ClassListPage />,
          },
          {
            path: 'classes/new',
            element: <ClassFormPage />,
          },
          {
            path: 'classes/:id',
            element: <ClassDetailPage />,
          },
          {
            path: 'classes/:id/edit',
            element: <ClassFormPage />,
          },
          // Subjects
          {
            path: 'subjects',
            element: <SubjectListPage />,
          },
          {
            path: 'subjects/new',
            element: <SubjectFormPage />,
          },
          {
            path: 'subjects/:id',
            element: <SubjectDetailPage />,
          },
          {
            path: 'subjects/:id/edit',
            element: <SubjectFormPage />,
          },
          // Teacher Assignments
          {
            path: 'teacher-assignments',
            element: <TeacherAssignmentListPage />,
          },
          {
            path: 'teacher-assignments/new',
            element: <TeacherAssignmentFormPage />,
          },
          // Student Enrollments
          {
            path: 'student-enrollments',
            element: <StudentEnrollmentListPage />,
          },
          {
            path: 'student-enrollments/new',
            element: <StudentEnrollmentFormPage />,
          },
          // Attendance
          {
            path: 'attendance',
            element: <AttendancePage />,
          },
          {
            path: 'attendance/mark',
            element: <AttendanceMarkPage />,
          },
          // Results
          {
            path: 'results',
            element: <ResultsPage />,
          },
          {
            path: 'results/new',
            element: <ResultFormPage />,
          },
          {
            path: 'results/:id/edit',
            element: <ResultFormPage />,
          },
          // Announcements
          {
            path: 'announcements',
            element: <AnnouncementListPage />,
          },
          {
            path: 'announcements/new',
            element: <AnnouncementFormPage />,
          },
          {
            path: 'announcements/:id/edit',
            element: <AnnouncementFormPage />,
          },
        ],
      },
      {
        path: '/unauthorized',
        element: (
          <div className="min-h-screen flex items-center justify-center">
            <div className="text-center">
              <h1 className="text-2xl font-bold text-red-600">Unauthorized</h1>
              <p className="mt-2 text-slate-600">
                This portal is for administrators only.
              </p>
              <a href="/login" className="mt-4 text-primary-500 hover:underline">
                Go to Login
              </a>
            </div>
          </div>
        ),
      },
      {
        path: '*',
        element: <NotFoundPage />,
      },
    ],
  },
])
