<script lang="ts">
  import { getTable, register } from '.'
  import { getLayout, Link } from '$/components'
  import { border } from '$/lib'
  import { url } from '@roxi/routify'

  export let bordered = false
  export let href: string | undefined = undefined
  export let title: string | undefined = undefined
  export let id: string | undefined = undefined

  const { cols, rows } = getTable()
  const { theme } = getLayout()

  register(rows)

  $: borders = bordered ? `${border.color[$theme]} border-t-2 border-b-2` : ''
</script>

{#if href}
  <div role="row" class="col-span-full h-row {borders}" {id}>
    <Link
      href={$url(href, {
        back: btoa(window.location.pathname + window.location.search + (id ? `#${id}` : '')),
      })}
      {title}>
      <div class="relative w-full h-full grid grid-cols-{cols} gap-x-md">
        <slot />
      </div>
    </Link>
  </div>
{:else}
  <div
    role="row"
    {title}
    class="relative col-span-full h-row grid grid-cols-{cols} gap-x-md {borders}"
    {id}>
    <slot />
  </div>
{/if}
