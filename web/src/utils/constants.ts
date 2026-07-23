export const APP_NAME = 'Student Status Checkup System'
export const APP_SHORT_NAME = 'SSCS'

export const ITEMS_PER_PAGE = 20
export const ITEMS_PER_PAGE_OPTIONS = [10, 20, 50, 100]

export const DATE_FORMAT = 'MMM d, yyyy'
export const DATETIME_FORMAT = 'MMM d, yyyy h:mm a'

export const ATTENDANCE_STATUSES = ['present', 'absent', 'late', 'excused'] as const
export const EXAM_TYPES = ['midterm', 'final', 'quiz', 'assignment', 'project'] as const
export const ANNOUNCEMENT_TARGETS = ['all', 'teachers', 'parents'] as const
export const ANNOUNCEMENT_PRIORITIES = ['low', 'normal', 'high', 'urgent'] as const
export const ENROLLMENT_STATUSES = ['active', 'transferred', 'withdrawn', 'graduated'] as const
export const RELATIONSHIP_TYPES = ['father', 'mother', 'guardian', 'other'] as const
export const GENDER_TYPES = ['male', 'female', 'other'] as const
