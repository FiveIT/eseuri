import { gql } from '@urql/svelte'

import type { WorkType, WorkSummary, Nullable } from '$/lib/types'

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

export type Data<T> = T extends Query<infer Name, infer Data, unknown>
  ? QueryData<Name, Data>
  : never

export type Vars<T> = T extends Query<string, unknown, infer Vars> ? Vars : never

const WORK_SUMMARY = gql`
  fragment WorkSummary on work_summaries {
    name
    url
    creator
    type
    work_count
  }
`

interface WorkSummariesVars {
  type: WorkType
}

export type WorkSummaries = Query<'work_summaries', WorkSummary[], WorkSummariesVars>

export const WORK_SUMMARIES = gql<Data<WorkSummaries>, Vars<WorkSummaries>>`
  ${WORK_SUMMARY}
  query getWorkSummaries($type: String!) {
    work_summaries(
      where: { type: { _eq: $type } }
      order_by: [{ work_count: desc }, { name: asc }]
    ) {
      ...WorkSummary
    }
  }
`

interface SearchWorkSummariesVars extends WorkSummariesVars {
  query: string
}

export type SearchWorkSummaries = Query<
  'find_work_summaries',
  WorkSummary[],
  SearchWorkSummariesVars
>

export const SEARCH_WORK_SUMMARIES = gql<Data<SearchWorkSummaries>, Vars<SearchWorkSummaries>>`
  ${WORK_SUMMARY}
  query searchWorkSummaries($query: String!, $type: String) {
    find_work_summaries(args: { query: $query, worktype: $type, fuzziness: 2 }) {
      ...WorkSummary
    }
  }
`

interface RegisterUserVars {
  firstName: string
  middleName: string | null
  lastName: string
  schoolID: number
}

export type RegisterUser = Query<'update_users', { affected_rows: number }, RegisterUserVars>

export const REGISTER_USER = gql<Data<RegisterUser>, Vars<RegisterUser>>`
  mutation registerUser(
    $firstName: String!
    $middleName: String
    $lastName: String!
    $schoolID: Int!
  ) {
    update_users(
      where: {}
      _set: {
        first_name: $firstName
        middle_name: $middleName
        last_name: $lastName
        school_id: $schoolID
      }
    ) {
      affected_rows
    }
  }
`

export type UserUpdatedAt = Query<'users', [{ updated_at: string | null }]>

export const USER_UPDATED_AT = gql<Data<UserUpdatedAt>, Vars<UserUpdatedAt>>`
  query userUpdatedAt {
    users(where: {}) {
      updated_at
    }
  }
`

interface ID {
  id: number
}

interface Namer {
  name: string
}

type Subject = ID & Namer

export type Titles = Query<'titles', Subject[]>

export const TITLES = gql<Data<Titles>, Vars<Titles>>`
  query getTitles {
    titles {
      id
      name
    }
  }
`

export type Characters = Query<'characters', Subject[]>

export const CHARACTERS = gql<Data<Characters>, Vars<Characters>>`
  query getCharacters {
    characters {
      id
      name
    }
  }
`

type WorkContent = Query<'works_by_pk', { content: string }, ID>

export const WORK_CONTENT = gql<Data<WorkContent>, Vars<WorkContent>>`
  query getWork($id: Int!) {
    works_by_pk(id: $id) {
      content
    }
  }
`
