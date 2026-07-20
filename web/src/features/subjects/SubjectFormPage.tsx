import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import { useSubject } from './useSubjects'
import { subjectService } from './subjectService'

const schema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  code: z.string().min(2, 'Code must be at least 2 characters'),
  description: z.string().optional(),
  is_active: z.boolean(),
})

type FormData = z.infer<typeof schema>

export default function SubjectFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const isEditing = Boolean(id)
  const [error, setError] = useState<string | null>(null)

  const { data: subject, isLoading: isLoadingSubject } = useSubject(id ?? '')

  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      code: '',
      description: '',
      is_active: true,
    },
  })

  useEffect(() => {
    if (subject) {
      reset({
        name: subject.name,
        code: subject.code,
        description: subject.description ?? '',
        is_active: subject.is_active,
      })
    }
  }, [subject, reset])

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)
      if (isEditing && id) {
        await subjectService.update(id, { ...data, description: data.description ?? null })
      } else {
        await subjectService.create({ ...data, description: data.description ?? null })
      }
      navigate('/subjects')
    } catch (err: any) {
      setError(err.message || 'An error occurred')
    }
  }

  if (isEditing && isLoadingSubject) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner />
      </div>
    )
  }

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Subjects', to: '/subjects' },
          { label: isEditing ? 'Edit' : 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEditing ? 'Edit Subject' : 'Add Subject'}
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
        <div className="grid grid-cols-2 gap-4">
          <Input label="Name" {...register('name')} error={errors.name?.message} />
          <Input label="Code" {...register('code')} error={errors.code?.message} />
        </div>
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
          <textarea
            {...register('description')}
            rows={3}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          {errors.description?.message && (
            <p className="mt-1 text-sm text-red-600">{errors.description.message}</p>
          )}
        </div>
        <div className="flex items-center gap-2">
          <input
            type="checkbox"
            id="is_active"
            {...register('is_active')}
            className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
          />
          <label htmlFor="is_active" className="text-sm font-medium text-slate-700">
            Active
          </label>
        </div>
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEditing ? 'Update Subject' : 'Create Subject'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/subjects')}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  )
}
