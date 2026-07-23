import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import { useAuth } from '@/contexts/AuthContext'
import { useCreateTeacherAssignment } from './useTeacherAssignments'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Select from '@/components/Select'
import Spinner from '@/components/Spinner'
import type { TeacherAssignment } from './teacherAssignmentTypes'

const schema = z.object({
  teacher_id: z.string().min(1, 'Teacher is required'),
  class_id: z.string().min(1, 'Class is required'),
  subject_id: z.string().min(1, 'Subject is required'),
  academic_year_id: z.string().min(1, 'Academic year is required'),
})

type FormData = z.infer<typeof schema>

export default function TeacherAssignmentFormPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const createMutation = useCreateTeacherAssignment()
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const { data: teachers = [], isLoading: loadingTeachers } = useQuery({
    queryKey: ['teachers-all'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('teachers')
        .select('id, employee_id, profiles!profile_id(id, first_name, last_name, email)')
        .order('employee_id')
      if (error) throw error
      return data ?? []
    },
  })

  const { data: classes = [], isLoading: loadingClasses } = useQuery({
    queryKey: ['classes-all'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('classes')
        .select('id, name, grade_level, section')
        .order('name')
      if (error) throw error
      return data ?? []
    },
  })

  const { data: subjects = [], isLoading: loadingSubjects } = useQuery({
    queryKey: ['subjects-all'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('subjects')
        .select('id, name, code')
        .order('name')
      if (error) throw error
      return data ?? []
    },
  })

  const { data: academicYears = [], isLoading: loadingYears } = useQuery({
    queryKey: ['academic-years-all'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('academic_years')
        .select('id, name, is_current')
        .order('name', { ascending: false })
      if (error) throw error
      return data ?? []
    },
  })

  const isLoading = loadingTeachers || loadingClasses || loadingSubjects || loadingYears

  const onSubmit = async (formData: FormData) => {
    try {
      await createMutation.mutateAsync({ ...formData, created_by: profile?.id ?? null } as Pick<TeacherAssignment, 'teacher_id' | 'class_id' | 'subject_id' | 'academic_year_id' | 'created_by'>)
      navigate('/teacher-assignments')
    } catch {
      // error shown via createMutation.isError
    }
  }

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Teacher Assignments', to: '/teacher-assignments' },
          { label: 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Add Teacher Assignment</h1>
      {createMutation.isError && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {createMutation.error?.message || 'Failed to create assignment'}
        </div>
      )}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <Select
          label="Teacher"
          placeholder="Select a teacher..."
          options={teachers.map((t: any) => ({
            value: t.id,
            label: `${t.profiles?.first_name ?? ''} ${t.profiles?.last_name ?? ''} (${t.employee_id})`,
          }))}
          {...register('teacher_id')}
          error={errors.teacher_id?.message}
        />
        <Select
          label="Class"
          placeholder="Select a class..."
          options={classes.map((c: any) => ({
            value: c.id,
            label: c.section ? `${c.name} - Section ${c.section}` : c.name,
          }))}
          {...register('class_id')}
          error={errors.class_id?.message}
        />
        <Select
          label="Subject"
          placeholder="Select a subject..."
          options={subjects.map((s: any) => ({
            value: s.id,
            label: `${s.name} (${s.code})`,
          }))}
          {...register('subject_id')}
          error={errors.subject_id?.message}
        />
        <Select
          label="Academic Year"
          placeholder="Select an academic year..."
          options={academicYears.map((y: any) => ({
            value: y.id,
            label: y.is_current ? `${y.name} (Current)` : y.name,
          }))}
          {...register('academic_year_id')}
          error={errors.academic_year_id?.message}
        />
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>Create Assignment</Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/teacher-assignments')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
