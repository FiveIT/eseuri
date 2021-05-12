export { default as Next } from './navigation/Next.svelte'
export { default as Back } from './navigation/Back.svelte'
export { default as Bookmark } from './bookmark'
// @ts-expect-error
export { default as Read, getReader } from './view/Read.svelte'
export { default as Review } from './view/Review.svelte'

import client, { relay } from '$/graphql/client'
import {
  WORK_CONTENT,
  SUBJECT_ID_FROM_URL,
  LIST_ESSAYS,
  LIST_CHARACTERIZATIONS,
  WORK_ID,
  ListSubjects,
  Relay,
  UNREVISED_WORK,
  WorkStatus,
} from '$/graphql/queries'
import { WorkType, Nullable, getName } from '$/lib'
import { graphQLSeed, fromQuery, handleGraphQLResponse, mapDefined } from '$/lib'

import { from, firstValueFrom, lastValueFrom, concat, of } from 'rxjs'
import type { Observable } from 'rxjs'
import { map, switchMap, tap } from 'rxjs/operators'
import type { Writable } from 'svelte/store'

export interface WorkID {
  id: Relay.ID
  workID: number
}

export interface WorkData extends WorkID {
  content: string
}

export type WorkBaseData = Omit<WorkData, 'id'>

export const defaultWorkData: WorkData = { id: '', content: '', workID: 0 }

const fetchWork = (id: Relay.ID): Promise<Omit<WorkData, 'workID'> | undefined> =>
  firstValueFrom(
    fromQuery(relay, WORK_CONTENT, { id }).pipe(
      map(res => ({ id, content: res.node.work.content }))
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
    .query(SUBJECT_ID_FROM_URL, { url, type })
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
                switchMap(v => from(v.edges)),
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

export const unrevisedWork = (workID: number): Observable<Nullable<UnrevisedWork>> =>
  concat(
    of(undefined),
    fromQuery(client, UNREVISED_WORK, { workID }).pipe(
      map(v => v.works_by_pk),
      mapDefined(
        (v): UnrevisedWork => ({
          type: v.essay ? 'essay' : 'characterization',
          title: v.essay ? v.essay.title.name : v.characterization!.character.name,
          user: v.user ? getName(v.user) : undefined,
          data: Promise.resolve({
            workID,
            content: v.content,
          }),
          status: v.status,
          teacherID: v.teacher_id!,
        }),
        null
      )
    )
  )

export const internalErrorNotification = {
  status: 'error',
  message: 'Nu s-au putut obține lucrările.',
  explanation: `Este o eroare internă, revino mai târziu - va fi rezolvată în scurt timp!`,
} as const

export interface WorkBase<T extends WorkBaseData = WorkBaseData> {
  title: string
  type: WorkType
  data: Promise<T>
}

export interface UnrevisedWork extends WorkBase {
  user?: string
  status: WorkStatus
  teacherID: number
}

export interface Work extends WorkBase<WorkData> {
  next(): void
  prev(): Promise<boolean>
  bookmarked: Writable<string | null>
  // eslint-disable-next-line no-unused-vars
  bookmark(name: string): Promise<void>
  removeBookmark(): Promise<void>
}
