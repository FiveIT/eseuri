import { fromMutation } from '$/lib'
import client from '$/graphql/client'
import { BOOKMARK, REMOVE_BOOKMARK } from '$/graphql/queries'
import { firstValueFrom } from 'rxjs'

export { default as default } from './Button.svelte'

export const bookmark = (workID: number, name: string) =>
  firstValueFrom(fromMutation(client, BOOKMARK, { workID, name }))

export const removeBookmark = (workID: number) =>
  firstValueFrom(fromMutation(client, REMOVE_BOOKMARK, { workID }))
