import { gql } from '@urql/svelte'

export const WORK_SUMMARIES = gql`
  query getWorkSummaries($type: String!) {
    work_summaries(
      where: { type: { _eq: $type } }
      order_by: { work_count: desc }
    ) {
      name
      creator
      type
      work_count
    }
  }
`

export const SEARCH_WORK_SUMMARIES = gql`
  query searchWorkSummaries($query: String!, $type: String!) {
    work_summaries(
      where: {
        _or: [{ name: { _ilike: $query } }, { creator: { _ilike: $query } }]
        type: { _eq: $type }
      }
      order_by: { work_count: desc }
    ) {
      name
      creator
      type
      work_count
    }
  }
`
