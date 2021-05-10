import type { Writable } from 'svelte/store'
import { onMount } from 'svelte'

// @ts-expect-error
export { default as Table, getTable } from './Table.svelte'
export { default as Header } from './Header.svelte'
export { default as Row } from './Row.svelte'
export { default as Cell } from './Cell.svelte'
export { default as Spinner } from './Spinner.svelte'
export { default as Error } from './Error.svelte'

export function register(store: Writable<number>, rows = 1) {
  onMount(() => {
    store.update(v => v + rows)

    return () => store.update(v => v - rows)
  })
}
