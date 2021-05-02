export type {
  BlobPropsInput,
  BlobFlipProps,
} from './components/blob/internal/store'

export type Role = 'student' | 'teacher'

export type Theme = 'white' | 'default'

export type WorkType = 'essay' | 'characterization'

export function isWorkType(s: string): s is WorkType {
  return s === 'essay' || s === 'characterization'
}

export interface Work {
  readonly name: string
  readonly creator: string
  readonly type: WorkType
  readonly work_count: number
}
export interface Bookmark {
  readonly type: string
  readonly bookmarkname: string
  readonly subject: string
  readonly time: string
}
