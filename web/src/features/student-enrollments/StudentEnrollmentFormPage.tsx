import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import { useAuth } from '@/contexts/AuthContext'
import { useCreateStudentEnrollment } from './useStudentEnrollments'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Spinner from '@/components/Spinner'
import type { StudentEnrollment } from './studentEnrollmentTypes'

const schema = z.object({
  student_id: z.string().min(1, 'Student is required'),
  class_id: z.string().min(1, 'Class is required'),
  enrollment_date: z.string().min(1, 'Enrollment date is required'),
})

type FormData = z.infer<typeof schema>

export default function StudentEnrollmentFormPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const createMutation = useCreateStudentEnrollment()
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      enrollment_date: new Date().toISOString().split('T')[0],
    },
  })

  const { data: students = [], isLoading: loadingStudents } = useQuery({
    queryKey: ['students-all'],
    queryFn: async () => {
      const { data } = await supabase
        .from('students')
        .select('id, first_name, last_name, student_id')
        .order('last_name')
      return data ?? []
    },
  })

  const { data: classes = [], isLoading: loadingClasses } = useQuery({
    queryKey: ['classes-all'],
    queryFn: async () => {
      const { data } = await supabase
        .from('classes')
        .select('id, name, grade_level, section')
        .order('name')
      return data ?? []
    },
  })

  const isLoading = loadingStudents || loadingClasses

  const onSubmit = async (formData: FormData) => {
    try {
      await createMutation.mutateAsync({ ...formData, created_by: profile?.id ?? null } as Pick<StudentEnrollment, 'student_id' | 'class_id' | 'enrollment_date' | 'created_by'>)
      navigate('/student-enrollments')
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
          { label: 'Student Enrollments', to: '/student-enrollments' },
          { label: 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Add Student Enrollment</h1>
      {createMutation.isError && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {createMutation.error?.message || 'Failed to create enrollment'}
        </div>
      )}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <Select
          label="Student"
          placeholder="Select a student..."
          options={students.map((s: any) => ({
            value: s.id,
            label: `${s.first_name} ${s.last_name} (${s.student_id})`,
          }))}
          {...register('student_id')}
          error={errors.student_id?.message}
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
        <Input
          label="Enrollment Date"
          type="date"
          {...register('enrollment_date')}
          error={errors.enrollment_date?.message}
        />
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>Create Enrollment</Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/student-enrollments')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
