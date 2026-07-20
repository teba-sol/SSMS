import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useAcademicYear, useCreateAcademicYear, useUpdateAcademicYear, useSetCurrentAcademicYear } from './useAcademicYears'
import Button from '@/components/Button'
import Input from '@/components/Input'
import { Card, CardHeader, CardTitle } from '@/components/Card'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { ArrowLeft } from 'lucide-react'

const academicYearSchema = z
  .object({
    name: z.string().min(1, 'Name is required'),
    start_date: z.string().min(1, 'Start date is required'),
    end_date: z.string().min(1, 'End date is required'),
    is_current: z.boolean(),
  })
  .refine((data) => new Date(data.end_date) > new Date(data.start_date), {
    message: 'End date must be after start date',
    path: ['end_date'],
  })

type AcademicYearFormData = z.infer<typeof academicYearSchema>

export default function AcademicYearFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const isEdit = Boolean(id)

  const { data: existingYear, isLoading: isLoadingYear } = useAcademicYear(id || '')
  const createMutation = useCreateAcademicYear()
  const updateMutation = useUpdateAcademicYear()
  const setCurrentMutation = useSetCurrentAcademicYear()

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
    reset,
  } = useForm<AcademicYearFormData>({
    resolver: zodResolver(academicYearSchema),
    defaultValues: {
      name: '',
      start_date: '',
      end_date: '',
      is_current: false,
    },
  })

  useEffect(() => {
    if (existingYear && isEdit) {
      reset({
        name: existingYear.name,
        start_date: existingYear.start_date,
        end_date: existingYear.end_date,
        is_current: existingYear.is_current,
      })
    }
  }, [existingYear, isEdit, reset])

  const [submitError, setSubmitError] = useState<string | null>(null)

  const onSubmit = async (formData: AcademicYearFormData) => {
    try {
      setSubmitError(null)
      if (isEdit && id) {
        await updateMutation.mutateAsync({
          id,
          updates: {
            name: formData.name,
            start_date: formData.start_date,
            end_date: formData.end_date,
          },
        })

        if (formData.is_current !== existingYear?.is_current && formData.is_current) {
          await setCurrentMutation.mutateAsync(id)
        }
      } else {
        await createMutation.mutateAsync({
          name: formData.name,
          start_date: formData.start_date,
          end_date: formData.end_date,
          is_current: formData.is_current,
          created_by: null,
        })
      }
      navigate('/academic-years')
    } catch (err) {
      setSubmitError((err as Error).message || 'Failed to save academic year')
    }
  }

  if (isEdit && isLoadingYear) {
    return (
      <div className="flex justify-center py-12">
        <Spinner />
      </div>
    )
  }

  if (isEdit && !existingYear) {
    return <ErrorMessage message="Academic year not found." />
  }

  const isPending = createMutation.isPending || updateMutation.isPending || setCurrentMutation.isPending

  return (
    <div className="space-y-6">
      <Breadcrumb items={[
        { label: 'Dashboard', to: '/dashboard' },
        { label: 'Academic Years', to: '/academic-years' },
        { label: isEdit ? 'Edit' : 'New' },
      ]} />
      <div className="flex items-center gap-4">
        <Button variant="ghost" onClick={() => navigate('/academic-years')}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-2xl font-bold">
          {isEdit ? 'Edit Academic Year' : 'Add Academic Year'}
        </h1>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Academic Year Details</CardTitle>
        </CardHeader>
        {submitError && (
          <div className="mx-6 mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {submitError}
          </div>
        )}
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 p-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            <Input label="Name *" placeholder="e.g. 2025-2026" {...register('name')} error={errors.name?.message} />
            <Input label="Start Date *" type="date" {...register('start_date')} error={errors.start_date?.message} />
            <Input label="End Date *" type="date" {...register('end_date')} error={errors.end_date?.message} />
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_current"
                checked={watch('is_current')}
                onChange={(e) => setValue('is_current', e.target.checked)}
                className="h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500"
              />
              <label htmlFor="is_current" className="text-sm font-medium text-slate-700">
                Set as current academic year
              </label>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <Button type="submit" isLoading={isPending}>
              {isEdit ? 'Save Changes' : 'Create Academic Year'}
            </Button>
            <Button type="button" variant="secondary" onClick={() => navigate('/academic-years')}>
              Cancel
            </Button>
          </div>
        </form>
      </Card>
    </div>
  )
}
