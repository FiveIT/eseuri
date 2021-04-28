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
  subscription getWorkSummaries($type: String!) {
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
