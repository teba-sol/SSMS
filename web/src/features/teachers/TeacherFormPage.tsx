import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useTeacher } from './useTeachers'
import { teacherService } from './teacherService'
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
  password: z.string().min(6, 'Password must be at least 6 characters'),
  employee_id: z.string().min(1, 'Required'),
  department: z.string().optional(),
  qualification: z.string().optional(),
  phone: z.string().optional(),
  hire_date: z.string().optional(),
})

const editSchema = z.object({
  email: z.string().optional(),
  first_name: z.string().min(1, 'Required'),
  last_name: z.string().min(1, 'Required'),
  employee_id: z.string().min(1, 'Required'),
  department: z.string().optional(),
  qualification: z.string().optional(),
  phone: z.string().optional(),
  hire_date: z.string().optional(),
})

type FormData = z.infer<typeof createSchema>

export default function TeacherFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEdit = Boolean(id)
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)

  const { data: existing, isLoading: loadingTeacher } = useTeacher(id ?? '')

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(isEdit ? editSchema : createSchema),
    values: existing ? {
      email: existing.profiles?.email ?? '',
      first_name: existing.profiles?.first_name ?? '',
      last_name: existing.profiles?.last_name ?? '',
      employee_id: existing.employee_id,
      department: existing.department ?? '',
      qualification: existing.qualification ?? '',
      phone: existing.profiles?.phone ?? '',
      hire_date: existing.hire_date ?? '',
    } : undefined,
  })

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)

      if (isEdit && id) {
        const profileId = existing?.profile_id
        if (profileId) {
          await supabase.from('profiles').update({
            first_name: data.first_name,
            last_name: data.last_name,
            phone: data.phone || null,
          }).eq('id', profileId)
        }
        await teacherService.update(id, {
          employee_id: data.employee_id,
          department: data.department || null,
          qualification: data.qualification || null,
          hire_date: data.hire_date || null,
        })
      } else {
        const { error: rpcError } = await supabase.rpc('create_user_account', {
          p_email: data.email,
          p_first_name: data.first_name,
          p_last_name: data.last_name,
          p_role: 'teacher',
          p_password: data.password,
          p_phone: data.phone || null,
          p_employee_id: data.employee_id,
          p_department: data.department || null,
          p_qualification: data.qualification || null,
          p_hire_date: data.hire_date || null,
        })

        if (rpcError) {
          throw new Error(rpcError.message)
        }
      }

      navigate('/teachers')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  if (isEdit && loadingTeacher) return <Spinner />
  if (isEdit && !existing) return <ErrorMessage message="Teacher not found" />

  return (
    <div>
      <Breadcrumb items={[
        { label: 'Dashboard', to: '/dashboard' },
        { label: 'Teachers', to: '/teachers' },
        { label: isEdit ? 'Edit' : 'New' },
      ]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEdit ? 'Edit Teacher' : 'Add Teacher'}
      </h1>
      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <div className="grid grid-cols-2 gap-4">
          {!isEdit && (
            <>
              <Input label="Email" type="email" {...register('email')} error={errors.email?.message} />
              <Input label="Password" type="password" {...register('password')} error={errors.password?.message} />
            </>
          )}
          <Input label="Employee ID" {...register('employee_id')} error={errors.employee_id?.message} />
          <Input label="First Name" {...register('first_name')} error={errors.first_name?.message} />
          <Input label="Last Name" {...register('last_name')} error={errors.last_name?.message} />
          <Input label="Department" {...register('department')} />
          <Input label="Qualification" {...register('qualification')} />
          <Input label="Phone" {...register('phone')} />
          <Input label="Hire Date" type="date" {...register('hire_date')} />
        </div>
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEdit ? 'Update Teacher' : 'Create Teacher'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/teachers')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
