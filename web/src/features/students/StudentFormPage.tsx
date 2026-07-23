import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { studentService } from './studentService'
import { useStudent } from './useStudents'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { GENDER_TYPES } from '@/utils/constants'

const schema = z.object({
  student_id: z.string().min(1, 'Required'),
  first_name: z.string().min(1, 'Required'),
  middle_name: z.string().optional(),
  last_name: z.string().min(1, 'Required'),
  date_of_birth: z.string().min(1, 'Required'),
  gender: z.string().optional(),
  address: z.string().optional(),
  emergency_contact: z.string().optional(),
  emergency_phone: z.string().optional(),
})

type FormData = z.infer<typeof schema>

export default function StudentFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEdit = Boolean(id)
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)

  const { data: existing, isLoading: loadingStudent } = useStudent(id ?? '')

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    values: existing ? {
      student_id: existing.student_id,
      first_name: existing.first_name,
      middle_name: existing.middle_name ?? '',
      last_name: existing.last_name,
      date_of_birth: existing.date_of_birth,
      gender: existing.gender ?? '',
      address: existing.address ?? '',
      emergency_contact: existing.emergency_contact ?? '',
      emergency_phone: existing.emergency_phone ?? '',
    } : undefined,
  })

  const onSubmit = async (data: FormData) => {
    try {
      setError(null)
      const payload = {
        ...data,
        gender: (data.gender as 'male' | 'female' | 'other') || null,
        middle_name: data.middle_name || null,
        address: data.address || null,
        emergency_contact: data.emergency_contact || null,
        emergency_phone: data.emergency_phone || null,
        created_by: null,
      }

      if (isEdit && id) {
        await studentService.update(id, payload)
      } else {
        await studentService.create(payload)
      }
      navigate('/students')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  if (isEdit && loadingStudent) return <Spinner />
  if (isEdit && !existing) return <ErrorMessage message="Student not found" />

  return (
    <div>
      <Breadcrumb items={[
        { label: 'Dashboard', to: '/dashboard' },
        { label: 'Students', to: '/students' },
        { label: isEdit ? 'Edit' : 'New' },
      ]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">
        {isEdit ? 'Edit Student' : 'Add Student'}
      </h1>
      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-slate-200 p-6 max-w-2xl space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Input label="Student ID" {...register('student_id')} error={errors.student_id?.message} />
          <Input label="First Name" {...register('first_name')} error={errors.first_name?.message} />
          <Input label="Middle Name" {...register('middle_name')} />
          <Input label="Last Name" {...register('last_name')} error={errors.last_name?.message} />
          <Input label="Date of Birth" type="date" {...register('date_of_birth')} error={errors.date_of_birth?.message} />
          <Select label="Gender" {...register('gender')} options={GENDER_TYPES.map(g => ({ value: g, label: g }))} placeholder="Select..." />
        </div>
        <Input label="Address" {...register('address')} />
        <div className="grid grid-cols-2 gap-4">
          <Input label="Emergency Contact" {...register('emergency_contact')} />
          <Input label="Emergency Phone" {...register('emergency_phone')} />
        </div>
        <div className="flex gap-3 pt-4">
          <Button type="submit" isLoading={isSubmitting}>
            {isEdit ? 'Update Student' : 'Create Student'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => navigate('/students')}>Cancel</Button>
        </div>
      </form>
    </div>
  )
}
