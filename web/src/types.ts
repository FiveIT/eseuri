export type {
  BlobPropsInput,
  BlobFlipProps,
} from './components/blob/internal/store'

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