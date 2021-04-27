import { gql } from '@apollo/client'

export const WORK_SUMMARIES = gql`
  query getWorkSummaries {
    work_summaries {
      name
      creator
      type
      work_count
    }
  }
`
