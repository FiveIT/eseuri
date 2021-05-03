export { default as Next } from './navigation/Next.svelte'
export { default as Back } from './navigation/Back.svelte'
export { default as Bookmark } from './Bookmark.svelte'
export { default as Reader } from './Reader.svelte'
export { default as Spinner } from '$/components/Spinner.svelte'

// @ts-expect-error
import Notifications, { notify } from '$/components/Notifications.svelte'
export { Notifications, notify }

import client, { relay } from '$/graphql/client'
import {
  WORK_CONTENT,
  SUBJECT_ID_FROM_URL,
  LIST_ESSAYS,
  LIST_CHARACTERIZATIONS,
  ListSubjects,
  Relay,
} from '$/graphql/queries'
import type { WorkType } from '$/lib/types'
import { handleGraphQLResponse, graphQLSeed } from '$/lib/util'

const fetchWork = (id: Relay.ID): Promise<string | undefined> =>
  relay
    .query(WORK_CONTENT, { id })
    .toPromise()
    .then(handleGraphQLResponse(resp => resp!.node.work?.content))

const WORK_LIMIT = 50
const defaultPageInfo: Relay.PageInfo = {
  startCursor: null,
  endCursor: null,
  hasNextPage: false,
  hasPreviousPage: false,
}

type WorksIterable = AsyncIterator<string> & {
  prev(): IteratorResult<string>
  fetchCurrent(): Promise<string>
}

export const works = async (url: string, type: WorkType) => {
  const res = await client.query(SUBJECT_ID_FROM_URL, { url }).toPromise()

  if (res.error) {
    throw res.error
  }

  if (res.data!.work_summaries.length === 0) {
    return
  }

  const { id, name, work_count } = res.data!.work_summaries[0]
  if (work_count === 0) {
    return { found: false, id, name } as const
  }

  const query = type === 'essay' ? LIST_ESSAYS : LIST_CHARACTERIZATIONS

  const vars = (seed: `${number}`, cursor: Relay.CursorVars) =>
    ({
      seed,
      subjectID: id,
      ...cursor,
    } as const)

  type Data = NonNullable<ListSubjects<'essays'>['data']>['list_essays_connection']

  return {
    found: true as true,
    id,
    name,
    [Symbol.asyncIterator](): WorksIterable {
      let seed = graphQLSeed()

      const fetched: Record<Relay.ID, string> = {}
      const ids: Relay.ID[] = []

      let current = 0
      let pageInfo = defaultPageInfo

      const fromCache = (): string | undefined => fetched[ids[current] || '']

      return {
        async fetchCurrent() {
          const content = (await fetchWork(ids[current]))!

          fetched[ids[current]] = content

          return content
        },
        async next() {
          const { hasNextPage, endCursor } = pageInfo

          if (current === ids.length) {
            if (!hasNextPage && endCursor !== null) {
              seed = graphQLSeed()
              pageInfo = defaultPageInfo

              return this.next()
            }

            const res = await relay
              .query(query, vars(seed, { after: pageInfo.endCursor, first: WORK_LIMIT }))
              .toPromise()

            if (res.error || !res.data) {
              throw res.error
            }

            const data: Data = (res.data as any)[`list_${type}s_connection`]
            pageInfo = data.pageInfo

            ids.push(...data.edges.map(e => e.node.id))
          }

          let value = fromCache()
          if (!value) {
            value = await this.fetchCurrent()
          }

          current++

          return { value }
        },
        prev() {
          if (--current <= 1) {
            return { value: undefined, done: true }
          }

          return { value: fromCache()! }
        },
      }
    },
  }
}

export const internalErrorNotification = {
  status: 'error',
  message: 'Nu s-au putut obține lucrările.',
  explanation: `Este o eroare internă, revino mai târziu - va fi rezolvată în scurt timp!`,
} as const

export interface Work {
  title: string
  content: Promise<string>
  next(): void
  prev(): boolean
}
