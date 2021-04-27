import type { WorkType, WorkSummary } from '../types'

export type { WorkType, WorkSummary }

type Nullable<T> = T | null | undefined

type QueryData<Name extends string, Data> = Nullable<
  {
    // eslint-disable-next-line no-unused-vars
    [key in Name]: Data
  }
>

type Query<Name extends string, Data, Vars> = {
  vars: Vars
  data: QueryData<Name, Data>
}

interface WorkSummariesVars {
  readonly type: WorkType
}

export type Data<T> = T extends Query<infer Name, infer Data, unknown>
  ? QueryData<Name, Data>
  : never

export type Vars<T> = T extends Query<string, unknown, infer Vars>
  ? Vars
  : never

export type WorkSummaries = Query<
  'work_summaries',
  WorkSummary[],
  WorkSummariesVars
>
