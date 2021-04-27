import { gql } from '@apollo/client/core'

export const WORK_SUMMARIES = gql`
  query getWorkSummaries($type: String!) {
    work_summaries(where: { type: { _eq: $type } }) {
      name
      creator
      type
      work_count
    }
  }
`
