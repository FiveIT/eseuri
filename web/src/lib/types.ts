export type { BlobPropsInput } from '$/components/blob/internal/store'

export type Role = 'student' | 'teacher'

export type Theme = 'white' | 'default'

export type WorkType = 'essay' | 'characterization'

export function isWorkType(s: string): s is WorkType {
  return s === 'essay' || s === 'characterization'
}

export function isNonNullable<T>(v: T): v is NonNullable<T> {
  return v != null
}

export interface WorkSummary {
  readonly name: string
  readonly url: string
  readonly creator: string
  readonly type: WorkType
  readonly work_count: number
}

export type Nullable<T> = T | null | undefined
