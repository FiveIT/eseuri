import type { WorkType, WorkSummary } from '../types'

export type { WorkType, WorkSummary }

type Nullable<T> = T | null | undefined

export type WorkSummaries = Nullable<{ work_summaries: WorkSummary[] }>
