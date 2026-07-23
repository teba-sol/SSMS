import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import { useCreateClass, useUpdateClass, useClass } from './useClasses'
import { useAllAcademicYears } from '@/features/academic-years/useAcademicYears'

const schema = z.object({
  name: z.string().min(1, 'Required'),
  academic_year_id: z.string().min(1, 'Required'),
  grade_level: z.coerce.number().min(1, 'Must be between 1 and 12').max(12, 'Must be between 1 and 12'),
  section: z.string().optional(),
  capacity: z.coerce.number().min(1, 'Must be at least 1'),
  room: z.string().optional(),
  is_active: z.boolean(),
})

type FormData = z.infer<typeof schema>

export default function ClassFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEditing = !!id
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)

  const { data: existingClass, isLoading: isLoadingClass } = useClass(id || '')
  const { data: academicYears, isLoading: isLoadingYears } = useAllAcademicYears()
  const createClass = useCreateClass()
  const updateClass = useUpdateClass()

  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      academic_year_id: '',
      grade_level: 1,
      section: '',
      capacity: 40,
      room: '',
      is_active: true,
    },
  })

  useEffect(() => {
    if (isEditing && existingClass) {
      reset({
        name: existingClass.name,
        academic_year_id: existingClass.academic_year_id,
        grade_level: existingClass.grade_level,
        section: existingClass.section ?? '',
        capacity: existingClass.capacity,
        room: existingClass.room ?? '',
        is_active: existingClass.is_active,
      })
    }
  }, [isEditing, existingClass, reset])

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)
      if (isEditing && id) {
        await updateClass.mutateAsync({
          id,
          updates: {
            ...data,
            section: data.section || null,
            room: data.room || null,
          },
        })
      } else {
        await createClass.mutateAsync({
          ...data,
          section: data.section || null,
          room: data.room || null,
          created_by: null,
        })
      }
      navigate('/classes')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  if (isEditing && isLoadingClass) return <Spinner />
  if (isEditing && !existingClass) return <div className="text-slate-500">Class not found.</div>

  const yearOptions = academicYears?.map((y) => ({ value: y.id, label: y.name })) ?? []

  return (
    <div>
      <Breadcrumb items={[{ label: 'School', to: '/dashboard' }, { label: 'Classes', to: '/classes' }, { label: isEditing ? 'Edit' : 'New' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">{isEditing ? 'Edit Class' : 'Add Class'}</h1>
      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      {isLoadingYears ? (
        <Spinner />
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input label="Class Name" placeholder="e.g. Grade 1A" {...register('name')} error={errors.name?.message} />
            <Select
              label="Academic Year"
              {...register('academic_year_id')}
              options={yearOptions}
              placeholder="Select academic year..."
              error={errors.academic_year_id?.message}
            />
            <Input label="Grade Level (1-12)" type="number" min={1} max={12} {...register('grade_level')} error={errors.grade_level?.message} />
            <Input label="Section" placeholder="e.g. A, B" {...register('section')} />
            <Input label="Capacity" type="number" min={1} {...register('capacity')} error={errors.capacity?.message} />
            <Input label="Room" placeholder="e.g. Room 101" {...register('room')} />
          </div>
          <div className="flex items-center gap-2 pt-2">
            <input
              type="checkbox"
              id="is_active"
              {...register('is_active')}
              className="h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500"
            />
            <label htmlFor="is_active" className="text-sm font-medium text-slate-700">Active</label>
          </div>
          <div className="flex gap-3 pt-4">
            <Button type="submit" isLoading={isSubmitting}>{isEditing ? 'Update Class' : 'Create Class'}</Button>
            <Button type="button" variant="secondary" onClick={() => navigate('/classes')}>Cancel</Button>
          </div>
        </form>
      )}
    </div>
  )
}
