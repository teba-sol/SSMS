import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Button from '@/components/Button'
import Select from '@/components/Select'
import Spinner from '@/components/Spinner'
import { useAnnouncement } from './useAnnouncements'
import { announcementService } from './announcementService'

const schema = z.object({
  title: z.string().min(1, 'Title is required'),
  content: z.string().min(1, 'Content is required'),
  target_audience: z.enum(['all', 'teachers', 'parents']),
  priority: z.enum(['low', 'normal', 'high', 'urgent']),
  is_published: z.boolean(),
})

type FormData = z.infer<typeof schema>

export default function AnnouncementFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const isEditing = Boolean(id)
  const [error, setError] = useState<string | null>(null)

  const { data: announcement, isLoading: isLoadingAnnouncement } = useAnnouncement(id ?? '')

  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      content: '',
      target_audience: 'all',
      priority: 'normal',
      is_published: false,
    },
  })

  useEffect(() => {
    if (announcement) {
      reset({
        title: announcement.title,
        content: announcement.content,
        target_audience: announcement.target_audience,
        priority: announcement.priority,
        is_published: announcement.is_published,
      })
    }
  }, [announcement, reset])

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)
      if (isEditing && id) {
        await announcementService.update(id, data)
      } else {
        await announcementService.create({ ...data, class_id: null })
      }
      navigate('/announcements')
    } catch (err: any) {
      setError(err.message || 'An error occurred')
    }
  }

  if (isEditing && isLoadingAnnouncement) {
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
          { label: 'Announcements', to: '/announcements' },
          { label: isEditing ? 'Edit' : 'New' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEditing ? 'Edit Announcement' : 'New Announcement'}
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
        <Input
          label="Title"
          {...register('title')}
          error={errors.title?.message}
        />
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Content</label>
          <textarea
            {...register('content')}
            rows={6}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          {errors.content?.message && (
            <p className="mt-1 text-sm text-red-600">{errors.content.message}</p>
          )}
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Select
            label="Target Audience"
            {...register('target_audience')}
            options={[
              { value: 'all', label: 'All' },
              { value: 'teachers', label: 'Teachers' },
              { value: 'parents', label: 'Parents' },
            ]}
          />
          <Select
            label="Priority"
            {...register('priority')}
            options={[
              { value: 'low', label: 'Low' },
              { value: 'normal', label: 'Normal' },
              { value: 'high', label: 'High' },
              { value: 'urgent', label: 'Urgent' },
            ]}
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            type="checkbox"
            id="is_published"
            {...register('is_published')}
            className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
          />
          <label htmlFor="is_published" className="text-sm font-medium text-slate-700">
            Publish immediately
          </label>
        </div>
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEditing ? 'Update Announcement' : 'Create Announcement'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/announcements')}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  )
}
