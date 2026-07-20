import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useParent } from './useParents'
import { parentService } from './parentService'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'

const createSchema = z.object({
  email: z.string().email('Valid email required'),
  first_name: z.string().min(1, 'Required'),
  last_name: z.string().min(1, 'Required'),
  phone: z.string().optional(),
})

const editSchema = z.object({
  email: z.string().optional(),
  first_name: z.string().min(1, 'Required'),
  last_name: z.string().min(1, 'Required'),
  phone: z.string().optional(),
})

type FormData = z.infer<typeof createSchema>

export default function ParentFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEdit = Boolean(id)
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)

  const { data: existing, isLoading: loadingParent } = useParent(id ?? '')

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(isEdit ? editSchema : createSchema),
    values: existing ? {
      email: existing.email,
      first_name: existing.first_name,
      last_name: existing.last_name,
      phone: existing.phone ?? '',
    } : undefined,
  })

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)

      if (isEdit && id) {
        await parentService.update(id, {
          first_name: data.first_name,
          last_name: data.last_name,
          phone: data.phone || undefined,
        })
      } else {
        const { error: rpcError } = await supabase.rpc('create_user_account', {
          p_email: data.email,
          p_first_name: data.first_name,
          p_last_name: data.last_name,
          p_role: 'parent',
          p_phone: data.phone || null,
        })

        if (rpcError) {
          throw new Error(rpcError.message)
        }
      }

      navigate('/parents')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  if (isEdit && loadingParent) return <Spinner />
  if (isEdit && !existing) return <ErrorMessage message="Parent not found" />

  return (
    <div>
      <Breadcrumb items={[
        { label: 'Dashboard', to: '/dashboard' },
        { label: 'Parents', to: '/parents' },
        { label: isEdit ? 'Edit' : 'New' },
      ]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEdit ? 'Edit Parent' : 'Add Parent'}
      </h1>
      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <div className="grid grid-cols-2 gap-4">
          {!isEdit && (
            <Input label="Email" type="email" {...register('email')} error={errors.email?.message} />
          )}
          <Input label="First Name" {...register('first_name')} error={errors.first_name?.message} />
          <Input label="Last Name" {...register('last_name')} error={errors.last_name?.message} />
          <Input label="Phone" {...register('phone')} />
        </div>
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEdit ? 'Update Parent' : 'Create Parent'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/parents')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
