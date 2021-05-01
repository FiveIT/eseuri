import { gql } from '@urql/svelte'
import type {
  SearchWorkSummaries,
  RegisterUser,
  WorkSummaries,
  UserUpdatedAt,
  Titles,
  Characters,
  Data,
  Vars,
} from './types'

const WORK_SUMMARY = gql`
  fragment WorkSummary on work_summaries {
    name
    url
    creator
    type
    work_count
  }
`

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

export const SEARCH_WORK_SUMMARIES = gql<
  Data<SearchWorkSummaries>,
  Vars<SearchWorkSummaries>
>`
  ${WORK_SUMMARY}
  query searchWorkSummaries($query: String!, $type: String) {
    find_work_summaries(
      args: { query: $query, worktype: $type, fuzziness: 2 }
    ) {
      ...WorkSummary
    }
  }
`

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

export const USER_UPDATED_AT = gql<Data<UserUpdatedAt>, Vars<UserUpdatedAt>>`
  query userUpdatedAt {
    users(where: {}) {
      updated_at
    }
  }
`

export const TITLES = gql<Data<Titles>, Vars<Titles>>`
  query getTitles {
    titles {
      id
      name
    }
  }
`

export const CHARACTERS = gql<Data<Characters>, Vars<Characters>>`
  query getCharacters {
    characters {
      id
      name
    }
  }
`
