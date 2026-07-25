import { useAuth } from '@/contexts/AuthContext'
import Breadcrumb from '@/components/Breadcrumb'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import { formatDate } from '@/utils/formatters'
import { Settings, User, Shield, Bell } from 'lucide-react'

export default function SettingsPage() {
  const { profile } = useAuth()
  
  const { data: systemInfo } = useQuery({
    queryKey: ['system-info'],
    queryFn: async () => {
      const { data: academicYears } = await supabase.from('academic_years').select('id, year_name, is_current').order('year_name', { ascending: false }).limit(5)
      return { academicYears }
    },
  })

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Settings' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Settings</h1>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Profile Settings */}
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <User size={20} className="text-primary-600" />
            <CardTitle>Profile Settings</CardTitle>
          </div>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-slate-500">Name</p>
              <p className="font-medium">{profile?.first_name} {profile?.last_name}</p>
            </div>
            <div>
              <p className="text-sm text-slate-500">Email</p>
              <p className="font-medium">{profile?.email}</p>
            </div>
            <div>
              <p className="text-sm text-slate-500">Role</p>
              <p className="font-medium capitalize">{profile?.role}</p>
            </div>
            <Button variant="secondary" size="sm">Edit Profile</Button>
          </div>
        </Card>

        {/* System Settings */}
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <Settings size={20} className="text-primary-600" />
            <CardTitle>System Settings</CardTitle>
          </div>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-slate-500">School Name</p>
              <p className="font-medium">Student Status Checkup System</p>
            </div>
            <div>
              <p className="text-sm text-slate-500">Current Academic Year</p>
              <p className="font-medium">
                {systemInfo?.academicYears?.find((y: any) => y.is_current)?.year_name || 'Not set'}
              </p>
            </div>
            <div>
              <p className="text-sm text-slate-500">Available Academic Years</p>
              <p className="font-medium">{systemInfo?.academicYears?.length || 0} years configured</p>
            </div>
          </div>
        </Card>

        {/* Notification Settings */}
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <Bell size={20} className="text-primary-600" />
            <CardTitle>Notification Settings</CardTitle>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">Email Notifications</p>
                <p className="text-sm text-slate-500">Receive email updates for important events</p>
              </div>
              <div className="h-6 w-11 bg-slate-200 rounded-full relative">
                <div className="h-5 w-5 bg-white rounded-full absolute top-0.5 left-0.5"></div>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">System Alerts</p>
                <p className="text-sm text-slate-500">Get notified about system issues</p>
              </div>
              <div className="h-6 w-11 bg-primary-600 rounded-full relative">
                <div className="h-5 w-5 bg-white rounded-full absolute top-0.5 right-0.5"></div>
              </div>
            </div>
          </div>
        </Card>

        {/* Security Settings */}
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <Shield size={20} className="text-primary-600" />
            <CardTitle>Security Settings</CardTitle>
          </div>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-slate-500">Last Login</p>
              <p className="font-medium">{formatDate(new Date().toISOString())}</p>
            </div>
            <div>
              <p className="text-sm text-slate-500">Session Status</p>
              <p className="font-medium text-green-600">Active</p>
            </div>
            <Button variant="secondary" size="sm">Change Password</Button>
          </div>
        </Card>
      </div>
    </div>
  )
}
