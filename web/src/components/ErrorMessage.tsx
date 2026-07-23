import { AlertCircle } from 'lucide-react'

export default function ErrorMessage({ message }: { message: string }) {
  return (
    <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
      <AlertCircle size={18} />
      {message}
    </div>
  )
}
