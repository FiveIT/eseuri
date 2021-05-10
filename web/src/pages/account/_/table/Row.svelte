<script lang="ts">
  import { getTable, register } from '.'
  import { getLayout, Link } from '$/components'
  import { border } from '$/lib'

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
  <div role="row" class="col-span-full {borders}" {id}>
    <Link
      href="{href}?back={encodeURI(
        window.location.pathname + window.location.search + (id ? `#${id}` : '')
      )}"
      {title}>
      <div class="w-full h-full grid grid-cols-{cols} gap-x-md">
        <slot />
      </div>
    </Link>
  </div>
{:else}
  <div role="row" {title} class="col-span-full grid grid-cols-{cols} gap-x-md {borders}" {id}>
    <slot />
  </div>
{/if}
