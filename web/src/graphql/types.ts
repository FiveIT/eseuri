import type { WorkType, WorkSummary } from '$/lib/types'

export type { WorkType, WorkSummary }

type Nullable<T> = T | null | undefined

type QueryData<Name extends string, Data> = Nullable<
  {
    // eslint-disable-next-line no-unused-vars
    [key in Name]: Data
  }
>

interface Typename {
  __typename: string
}

type Query<Name extends string, Data = Typename, Vars = object> = {
  vars: Vars
  data: QueryData<Name, Data>
}

interface WorkSummariesVars {
  type: WorkType
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

interface SearchWorkSummariesVars extends WorkSummariesVars {
  query: `${string}%`
}

export type SearchWorkSummaries = Query<
  'work_summaries',
  WorkSummary[],
  SearchWorkSummariesVars
>

interface RegisterUserVars {
  firstName: string
  middleName: string | null
  lastName: string
  schoolID: number
}

export type RegisterUser = Query<
  'update_users',
  { affected_rows: number },
  RegisterUserVars
>

export type UserUpdatedAt = Query<'users', [{ updated_at: string | null }]>
