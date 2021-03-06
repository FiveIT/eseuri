import { fromMutation, fromQuery } from '$/lib'
import client from '$/graphql/client'
import { BOOKMARK, REMOVE_BOOKMARK, IS_BOOKMARKED } from '$/graphql/queries'
import { firstValueFrom } from 'rxjs'
import { map } from 'rxjs/operators'

export { default as default } from './Bookmark.svelte'

export const bookmark = (workID: number, name: string) =>
  firstValueFrom(fromMutation(client, BOOKMARK, { workID, name }))

export const removeBookmark = (workID: number) =>
  firstValueFrom(fromMutation(client, REMOVE_BOOKMARK, { workID }))

export const isBookmarked = (workID: number) =>
  firstValueFrom(
    fromQuery(client, IS_BOOKMARKED, { workID }, { requestPolicy: 'cache-and-network' }).pipe(
      map(v => v.bookmarks[0]?.name || '')
    )
  )
