import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import { useAuth } from '@/contexts/AuthContext'
import { useCreateActivity } from './useActivities'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Spinner from '@/components/Spinner'

const schema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  activity_type: z.string().min(1, 'Type is required'),
  activity_date: z.string().min(1, 'Date is required'),
  location: z.string().optional(),
  class_id: z.string().optional(),
  academic_year_id: z.string().min(1, 'Academic year is required'),
})

type FormData = z.infer<typeof schema>

export default function ActivityFormPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const createMutation = useCreateActivity()
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      activity_date: new Date().toISOString().split('T')[0],
    },
  })

  const { data: academicYears = [], isLoading: loadingYears } = useQuery({
    queryKey: ['academic-years-all'],
    queryFn: async () => {
      const { data } = await supabase.from('academic_years').select('id, name, is_current').order('name', { ascending: false })
      return data ?? []
    },
  })

  const { data: classes = [], isLoading: loadingClasses } = useQuery({
    queryKey: ['classes-all'],
    queryFn: async () => {
      const { data } = await supabase.from('classes').select('id, name, grade_level, section').order('name')
      return data ?? []
    },
  })

  if (loadingYears || loadingClasses) return <Spinner />

  const onSubmit = async (formData: FormData) => {
    try {
      await createMutation.mutateAsync({
        ...formData,
        description: formData.description || undefined,
        location: formData.location || undefined,
        class_id: formData.class_id || undefined,
        created_by: profile?.id ?? null,
      } as any)
      navigate('/activities')
    } catch {
      // error shown via createMutation.isError
    }
  }

  const activityTypes = ['sports', 'club', 'event', 'field_trip', 'competition', 'exam', 'meeting', 'other']

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Activities', to: '/activities' },
          { label: 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Add Activity</h1>
      {createMutation.isError && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {createMutation.error?.message || 'Failed to create activity'}
        </div>
      )}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <Input label="Title" {...register('title')} error={errors.title?.message} placeholder="Sports Day, Science Fair..." />
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
          <textarea {...register('description')} rows={3} className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500" placeholder="Optional description..." />
        </div>
        <Select
          label="Type"
          placeholder="Select type..."
          options={activityTypes.map((t) => ({ value: t, label: t.charAt(0).toUpperCase() + t.slice(1).replace('_', ' ') }))}
          {...register('activity_type')}
          error={errors.activity_type?.message}
        />
        <Input label="Date" type="date" {...register('activity_date')} error={errors.activity_date?.message} />
        <Input label="Location" {...register('location')} placeholder="Optional location..." />
        <Select
          label="Class (optional, leave blank for school-wide)"
          placeholder="School-wide"
          options={classes.map((c: any) => ({ value: c.id, label: c.section ? `${c.name} - Section ${c.section}` : c.name }))}
          {...register('class_id')}
        />
        <Select
          label="Academic Year"
          placeholder="Select year..."
          options={academicYears.map((y: any) => ({ value: y.id, label: y.is_current ? `${y.name} (Current)` : y.name }))}
          {...register('academic_year_id')}
          error={errors.academic_year_id?.message}
        />
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={createMutation.isPending}>Create Activity</Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/activities')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
