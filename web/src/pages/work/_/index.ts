export { default as Next } from './navigation/Next.svelte'
export { default as Back } from './navigation/Back.svelte'
export { default as Bookmark } from './Bookmark.svelte'
export { default as Reader } from './Reader.svelte'
export { default as Carousel } from '@tmaxmax/renderless-svelte/src/Carousel.svelte'

// @ts-expect-error
import Notifications, { notify } from '$/components/Notifications.svelte'
export { Notifications, notify }

import client from '$/graphql/client'
import { WORK_CONTENT } from '$/graphql/queries'
import { handleGraphQLResponse } from '$/lib/util'

export const fetchWork = (id: number): Promise<string | undefined> =>
  client
    .query(WORK_CONTENT, { id })
    .toPromise()
    .then(handleGraphQLResponse(resp => resp?.works_by_pk.content))
