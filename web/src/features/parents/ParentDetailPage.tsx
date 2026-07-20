import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useParent, useParentChildren } from './useParents'
import { parentService } from './parentService'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'
import { Users, Mail, Phone, Link, Unlink } from 'lucide-react'

const RELATIONSHIPS = [
  { value: 'father', label: 'Father' },
  { value: 'mother', label: 'Mother' },
  { value: 'guardian', label: 'Guardian' },
  { value: 'other', label: 'Other' },
]

export default function ParentDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: parent, isLoading, error } = useParent(id!)
  const { data: children = [], isLoading: loadingChildren, refetch: refetchChildren } = useParentChildren(id!)

  const [showLinkForm, setShowLinkForm] = useState(false)
  const [studentSearch, setStudentSearch] = useState('')
  const [selectedStudentId, setSelectedStudentId] = useState('')
  const [relationship, setRelationship] = useState('guardian')
  const [searchResults, setSearchResults] = useState<{ id: string; first_name: string; last_name: string; student_id: string }[]>([])
  const [linkError, setLinkError] = useState<string | null>(null)

  const toggleMutation = useMutation({
    mutationFn: () => parentService.toggleActive(parent!.id, !parent!.is_active),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['parents', id] })
      queryClient.invalidateQueries({ queryKey: ['parents'] })
    },
  })

  const linkMutation = useMutation({
    mutationFn: () => parentService.linkStudent(id!, selectedStudentId, relationship),
    onSuccess: () => {
      setShowLinkForm(false)
      setSelectedStudentId('')
      setStudentSearch('')
      setSearchResults([])
      setLinkError(null)
      refetchChildren()
    },
    onError: (err: Error) => setLinkError(err.message),
  })

  const unlinkMutation = useMutation({
    mutationFn: (psId: string) => parentService.unlinkStudent(psId),
    onSuccess: () => refetchChildren(),
  })

  const handleSearchStudents = async (value: string) => {
    setStudentSearch(value)
    if (value.length < 2) { setSearchResults([]); return }
    const results = await parentService.searchStudents(value)
    setSearchResults(results.filter((s) => !children.some((c) => c.student_id === s.id)))
  }

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage message={error.message} />
  if (!parent) return <ErrorMessage message="Parent not found" />

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Parents', to: '/parents' },
          { label: `${parent.first_name} ${parent.last_name}` },
        ]}
      />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">
          {parent.first_name} {parent.last_name}
        </h1>
        <div className="flex items-center gap-3">
          <Button onClick={() => navigate(`/parents/${id}/edit`)}>Edit</Button>
          <Button
            variant={parent.is_active ? 'danger' : 'primary'}
            onClick={() => {
              if (window.confirm(parent.is_active ? 'Deactivate this parent?' : 'Activate this parent?')) {
                toggleMutation.mutate()
              }
            }}
            isLoading={toggleMutation.isPending}
          >
            {parent.is_active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{children.length}</p>
              <p className="text-xs text-slate-500">Children</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Mail className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{parent.email}</p>
              <p className="text-xs text-slate-500">Email</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
              <Phone className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{parent.phone ?? '-'}</p>
              <p className="text-xs text-slate-500">Phone</p>
            </div>
          </div>
        </Card>
      </div>

      <Card>
        <div className="flex items-center justify-between mb-4">
          <CardTitle>Linked Children ({children.length})</CardTitle>
          <Button onClick={() => setShowLinkForm(!showLinkForm)}>
            <Link className="w-4 h-4 mr-1" /> Link Child
          </Button>
        </div>

        {showLinkForm && (
          <div className="mb-4 p-4 bg-slate-50 rounded-lg border border-slate-200 space-y-3">
            {linkError && (
              <div className="p-2 bg-red-50 border border-red-200 rounded text-red-700 text-sm">{linkError}</div>
            )}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Search Student</label>
              <input
                type="text"
                value={studentSearch}
                onChange={(e) => handleSearchStudents(e.target.value)}
                placeholder="Type student name or ID..."
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            {searchResults.length > 0 && (
              <div className="max-h-40 overflow-y-auto border border-slate-200 rounded-lg">
                {searchResults.map((s) => (
                  <div
                    key={s.id}
                    onClick={() => { setSelectedStudentId(s.id); setStudentSearch(`${s.first_name} ${s.last_name} (${s.student_id})`); setSearchResults([]) }}
                    className="px-3 py-2 hover:bg-blue-50 cursor-pointer text-sm flex justify-between"
                  >
                    <span>{s.first_name} {s.last_name}</span>
                    <span className="text-slate-400">{s.student_id}</span>
                  </div>
                ))}
              </div>
            )}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Relationship</label>
              <select
                value={relationship}
                onChange={(e) => setRelationship(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {RELATIONSHIPS.map((r) => (
                  <option key={r.value} value={r.value}>{r.label}</option>
                ))}
              </select>
            </div>
            <div className="flex gap-2">
              <Button
                onClick={() => linkMutation.mutate()}
                isLoading={linkMutation.isPending}
                disabled={!selectedStudentId}
              >
                Link Student
              </Button>
              <Button variant="secondary" onClick={() => { setShowLinkForm(false); setSearchResults([]); setLinkError(null) }}>
                Cancel
              </Button>
            </div>
          </div>
        )}

        {loadingChildren ? (
          <Spinner />
        ) : children.length === 0 ? (
          <p className="text-sm text-slate-400 text-center py-8">No children linked yet. Click "Link Child" to add one.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200">
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Student ID</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Name</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Relationship</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Actions</th>
                </tr>
              </thead>
              <tbody>
                {children.map((c) => (
                  <tr key={c.id} className="border-b border-slate-100">
                    <td className="py-3 px-4 font-medium text-slate-900">{c.students?.student_id ?? '-'}</td>
                    <td className="py-3 px-4">
                      <span
                        className="text-slate-700 hover:text-blue-600 cursor-pointer"
                        onClick={() => navigate(`/students/${c.student_id}`)}
                      >
                        {c.students?.first_name} {c.students?.last_name}
                      </span>
                    </td>
                    <td className="py-3 px-4 capitalize text-slate-500">{c.relationship}</td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => {
                          if (window.confirm('Remove this child link?')) unlinkMutation.mutate(c.id)
                        }}
                        className="text-red-500 hover:text-red-700"
                      >
                        <Unlink className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
