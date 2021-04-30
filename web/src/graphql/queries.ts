import { gql } from '@urql/svelte'

const WORK_SUMMARY = gql`
  fragment WorkSummary on work_summaries {
    name
    creator
    type
    work_count
  }
`

export const WORK_SUMMARIES = gql`
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

export const SEARCH_WORK_SUMMARIES = gql`
  ${WORK_SUMMARY}
  query searchWorkSummaries($query: String!, $type: String!) {
    work_summaries(
      where: {
        _or: [{ name: { _ilike: $query } }, { creator: { _ilike: $query } }]
        type: { _eq: $type }
      }
      order_by: [{ work_count: desc }, { name: asc }]
    ) {
      ...WorkSummary
    }
  }
`

export const REGISTER_USER = gql`
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

export const USER_UPDATED_AT = gql`
  query userUpdatedAt {
    users(where: {}) {
      updated_at
    }
  }
`

export const TITLES = gql`
  query getTitles {
    titles {
      id
      name
    }
  }
`

export const CHARACTERS = gql`
  query getCharacters {
    characters {
      id
      name
    }
  }
`
