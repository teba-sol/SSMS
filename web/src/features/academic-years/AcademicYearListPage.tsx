import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useDebounce } from '@/hooks/useDebounce'
import { usePagination } from '@/hooks/usePagination'
import { useAcademicYears, useSetCurrentAcademicYear, useDeleteAcademicYear } from './useAcademicYears'
import { formatDate } from '@/utils/formatters'
import Button from '@/components/Button'
import Input from '@/components/Input'
import DataTable from '@/components/DataTable'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import { Plus, Search } from 'lucide-react'
import type { AcademicYear } from './academicYearsTypes'

export default function AcademicYearListPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { page, perPage, setPage } = usePagination()
  const { data, isLoading } = useAcademicYears(page, debouncedSearch)
  const setCurrentMutation = useSetCurrentAcademicYear()
  const deleteMutation = useDeleteAcademicYear()

  const totalPages = data ? Math.ceil(data.total / perPage) : 0

  const columns = [
    {
      key: 'name',
      header: 'Name',
    },
    {
      key: 'start_date',
      header: 'Start Date',
      render: (row: AcademicYear) => formatDate(row.start_date),
    },
    {
      key: 'end_date',
      header: 'End Date',
      render: (row: AcademicYear) => formatDate(row.end_date),
    },
    {
      key: 'is_current',
      header: 'Status',
      render: (row: AcademicYear) => (
        <span
          className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
            row.is_current
              ? 'bg-green-100 text-green-800'
              : 'bg-slate-100 text-slate-600'
          }`}
        >
          {row.is_current ? 'Current' : 'Inactive'}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (row: AcademicYear) => (
        <div className="flex items-center gap-2">
          <button
            onClick={(e) => { e.stopPropagation(); navigate(`/academic-years/${row.id}/edit`) }}
            className="text-sm text-primary-600 hover:underline"
          >
            Edit
          </button>
          {!row.is_current && (
            <>
              <button
                onClick={(e) => { e.stopPropagation(); setCurrentMutation.mutate(row.id) }}
                className="text-sm text-green-600 hover:underline"
                disabled={setCurrentMutation.isPending}
              >
                Set Current
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  if (window.confirm('Delete this academic year?')) deleteMutation.mutate(row.id)
                }}
                className="text-sm text-red-600 hover:underline"
              >
                Delete
              </button>
            </>
          )}
        </div>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Academic Years' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Academic Years</h1>
        <Button onClick={() => navigate('/academic-years/new')}>
          <Plus size={16} /> Add Academic Year
        </Button>
      </div>
      <div className="bg-white rounded-xl border border-slate-200 p-6">
        <div className="mb-4 relative max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
          <Input
            placeholder="Search..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            className="pl-10"
          />
        </div>
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(item) => item.id}
          onRowClick={(item) => navigate(`/academic-years/${item.id}/edit`)}
        />
        <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
      </div>
    </div>
  )
}
