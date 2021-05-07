export { default as Next } from './navigation/Next.svelte'
export { default as Back } from './navigation/Back.svelte'
export { default as Bookmark } from './Bookmark.svelte'
// @ts-expect-error
export { default as Reader, getWork } from './Reader.svelte'

import client, { relay } from '$/graphql/client'
import {
  WORK_CONTENT,
  SUBJECT_ID_FROM_URL,
  LIST_ESSAYS,
  LIST_CHARACTERIZATIONS,
  BOOKMARK,
  WORK_ID,
  ListSubjects,
  Relay,
  REMOVE_BOOKMARK,
} from '$/graphql/queries'
import type { WorkType } from '$/lib'
import { graphQLSeed, fromQuery, fromMutation, handleGraphQLResponse } from '$/lib'

import { from, firstValueFrom, lastValueFrom } from 'rxjs'
import { map, mergeMap, tap } from 'rxjs/operators'

export interface WorkID {
  id: Relay.ID
  workID: number
}

export interface WorkData extends WorkID {
  content: string
}

export const defaultWorkData: WorkData = { id: '', content: '', workID: 0 }

const fetchWork = (id: Relay.ID): Promise<Omit<WorkData, 'workID'> | undefined> =>
  firstValueFrom(
    fromQuery(relay, WORK_CONTENT, { id }).pipe(
      map(res => (res ? { id, content: res.node.work.content } : undefined))
    )
  )

const WORK_LIMIT = 50
const defaultPageInfo: Relay.PageInfo = {
  startCursor: null,
  endCursor: null,
  hasNextPage: false,
  hasPreviousPage: false,
}

type WorksIterable = AsyncIterator<WorkData, WorkData> & {
  prev(): Promise<IteratorResult<WorkData, WorkData | undefined>>
  fetchCurrent(): Promise<WorkData>
}

export const works = async (url: string, type: WorkType, beginWith?: string) => {
  const res = await client
    .query(SUBJECT_ID_FROM_URL, { url })
    .toPromise()
    .then(handleGraphQLResponse(v => (v?.work_summaries.length ? v.work_summaries[0] : undefined)))

  if (!res) {
    return
  }

  const { id, name, work_count } = res
  if (work_count === 0) {
    return { found: false, id, name } as const
  }

  const query = type === 'essay' ? LIST_ESSAYS : LIST_CHARACTERIZATIONS
  const vars = (seed: `${number}`, cursor: Relay.CursorVars) => ({
    seed,
    subjectID: id,
    ...cursor,
  })

  let beginID: WorkID | undefined
  if (beginWith) {
    beginID = await firstValueFrom(
      fromQuery(relay, WORK_ID, { id: beginWith }).pipe(
        map(v => ({
          id: beginWith,
          workID: v.node.work_id,
        }))
      )
    )
  }

  type Data = NonNullable<ListSubjects<'essays'>['data']>['list_essays_connection']

  return {
    found: true as true,
    id,
    name,
    [Symbol.asyncIterator](): WorksIterable {
      let seed = graphQLSeed()

      const ids: WorkID[] = []
      if (beginID) {
        ids.push(beginID)
      }

      let current = -1
      let page = defaultPageInfo

      return {
        fetchCurrent: () =>
          fetchWork(ids[current].id).then(w => ({
            ...w!,
            ...ids[current],
          })),
        async next() {
          if (++current === ids.length) {
            if (!page.hasNextPage && page.endCursor !== null) {
              seed = graphQLSeed()
              page = defaultPageInfo
              --current

              return this.next()
            }

            const v = vars(seed, { after: page.endCursor, first: WORK_LIMIT })
            await lastValueFrom(
              fromQuery(relay, query, v).pipe(
                map(v => (v! as any)[`list_${type}s_connection`] as Data),
                tap(r => (page = r.pageInfo)),
                mergeMap(v => from(v.edges)),
                tap(r => ids.push({ id: r.node.id, workID: r.node.work_id }))
              )
            )
          }

          return { value: await this.fetchCurrent() }
        },
        async prev() {
          if (current-- === -1) {
            return { value: undefined, done: true }
          }

          return { value: await this.fetchCurrent(), done: current !== 0 }
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
  data: Promise<WorkData>
  next(): void
  prev(): Promise<boolean>
}

export const bookmark = (workID: number) =>
  firstValueFrom(fromMutation(client, BOOKMARK, { workID }))

export const removeBookmark = (workID: number) =>
  firstValueFrom(fromMutation(client, REMOVE_BOOKMARK, { workID }))
