import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import { resultsService } from './resultsService'
import { EXAM_TYPES } from '@/utils/constants'
import { useAuth } from '@/contexts/AuthContext'

const schema = z.object({
  student_id: z.string().min(1, 'Student is required'),
  teacher_assignment_id: z.string().min(1, 'Teacher assignment is required'),
  exam_type: z.enum(['midterm', 'final', 'quiz', 'assignment', 'project']),
  exam_date: z.string().min(1, 'Exam date is required'),
  marks_obtained: z.coerce.number().min(0, 'Must be at least 0').optional().nullable(),
  total_marks: z.coerce.number().min(1, 'Must be at least 1').optional().nullable(),
  grade: z.string().optional().nullable(),
  remarks: z.string().optional().nullable(),
})

type FormData = z.infer<typeof schema>

export default function ResultFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEditing = Boolean(id)
  const navigate = useNavigate()
  const { profile } = useAuth()
  const [error, setError] = useState<string | null>(null)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

  const { data: students } = useQuery({
    queryKey: ['students-list'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('students')
        .select('id, first_name, last_name, student_id')
        .order('last_name')
      if (error) throw error
      return data
    },
  })

  const { data: assignments } = useQuery({
    queryKey: ['teacher-assignments-list'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('teacher_assignments')
        .select('id, classes(name), subjects(name, code)')
      if (error) throw error
      return data
    },
  })

  const { data: existingResult, isLoading: isLoadingResult } = useQuery({
    queryKey: ['result', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('results')
        .select('*')
        .eq('id', id)
        .single()
      if (error) throw error
      return data
    },
    enabled: isEditing,
  })

  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      student_id: '',
      teacher_assignment_id: '',
      exam_type: 'quiz',
      exam_date: new Date().toISOString().split('T')[0],
      marks_obtained: null,
      total_marks: null,
      grade: '',
      remarks: '',
    },
  })

  useEffect(() => {
    if (isEditing && existingResult) {
      reset({
        student_id: existingResult.student_id,
        teacher_assignment_id: existingResult.teacher_assignment_id,
        exam_type: existingResult.exam_type,
        exam_date: existingResult.exam_date,
        marks_obtained: existingResult.marks_obtained,
        total_marks: existingResult.total_marks,
        grade: existingResult.grade ?? '',
        remarks: existingResult.remarks ?? '',
      })
    }
  }, [isEditing, existingResult, reset])

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)
      if (isEditing && id) {
        await resultsService.update(id, {
          ...data,
          marks_obtained: data.marks_obtained ?? null,
          total_marks: data.total_marks ?? null,
          grade: data.grade || null,
          remarks: data.remarks || null,
        })
      } else {
        await resultsService.create({
          student_id: data.student_id,
          teacher_assignment_id: data.teacher_assignment_id,
          exam_type: data.exam_type,
          exam_date: data.exam_date,
          marks_obtained: data.marks_obtained ?? null,
          total_marks: data.total_marks ?? null,
          grade: data.grade || null,
          remarks: data.remarks || null,
          created_by: profile?.id || null,
        })
      }
      navigate('/results')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  const handleDelete = async () => {
    if (!id) return
    try {
      await resultsService.delete(id)
      navigate('/results')
    } catch (err) {
      setError((err as Error).message)
      setShowDeleteConfirm(false)
    }
  }

  if (isEditing && isLoadingResult) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner />
      </div>
    )
  }

  if (isEditing && !existingResult) {
    return <div className="text-slate-500">Result not found.</div>
  }

  const studentOptions =
    students?.map((s) => ({
      value: s.id,
      label: `${s.last_name}, ${s.first_name} (${s.student_id})`,
    })) ?? []

  const assignmentOptions =
    assignments?.map((a) => ({
      value: a.id,
      label: `${(a.classes as any)?.name ?? 'N/A'} - ${(a.subjects as any)?.name ?? 'N/A'}`,
    })) ?? []

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Results', to: '/results' },
          { label: isEditing ? 'Edit' : 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEditing ? 'Edit Result' : 'Add Result'}
      </h1>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {error}
        </div>
      )}

      <form
        onSubmit={handleSubmit(onSubmit)}
        className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4"
      >
        <Select
          label="Student"
          {...register('student_id')}
          options={studentOptions}
          placeholder="Select student..."
          error={errors.student_id?.message}
        />

        <Select
          label="Teacher Assignment (Class - Subject)"
          {...register('teacher_assignment_id')}
          options={assignmentOptions}
          placeholder="Select assignment..."
          error={errors.teacher_assignment_id?.message}
        />

        <div className="grid grid-cols-2 gap-4">
          <Select
            label="Exam Type"
            {...register('exam_type')}
            options={EXAM_TYPES.map((t) => ({
              value: t,
              label: t.charAt(0).toUpperCase() + t.slice(1),
            }))}
            error={errors.exam_type?.message}
          />
          <Input
            label="Exam Date"
            type="date"
            {...register('exam_date')}
            error={errors.exam_date?.message}
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Input
            label="Marks Obtained"
            type="number"
            min={0}
            step="any"
            {...register('marks_obtained')}
            error={errors.marks_obtained?.message}
          />
          <Input
            label="Total Marks"
            type="number"
            min={1}
            step="any"
            {...register('total_marks')}
            error={errors.total_marks?.message}
          />
        </div>

        <Input
          label="Grade"
          placeholder="e.g. A, B+, 85%"
          {...register('grade')}
          error={errors.grade?.message}
        />

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Remarks</label>
          <textarea
            {...register('remarks')}
            rows={3}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            placeholder="Optional remarks..."
          />
          {errors.remarks?.message && (
            <p className="mt-1 text-sm text-red-600">{errors.remarks.message}</p>
          )}
        </div>

        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEditing ? 'Update Result' : 'Create Result'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/results')}>
            Cancel
          </Button>
          {isEditing && (
            <Button type="button" variant="danger" onClick={() => setShowDeleteConfirm(true)}>
              Delete
            </Button>
          )}
        </div>
      </form>

      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6 space-y-4">
            <h2 className="text-lg font-semibold text-slate-900">Delete Result</h2>
            <p className="text-sm text-slate-600">
              Are you sure you want to delete this result? This action cannot be undone.
            </p>
            <div className="flex gap-3 justify-end">
              <Button variant="secondary" onClick={() => setShowDeleteConfirm(false)}>
                Cancel
              </Button>
              <Button variant="danger" onClick={handleDelete}>
                Delete
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
