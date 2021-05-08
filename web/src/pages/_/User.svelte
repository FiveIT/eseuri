<script lang="ts">
  import Base from './Base.svelte'
  import { TypeSelector } from '$/components'
  import type { WorkType } from '$/lib'
  import { WORK_SUMMARIES } from '$/graphql/queries'

  import { operationStore, query } from '@urql/svelte'

  let type: WorkType = 'essay'

  const content = query(operationStore(WORK_SUMMARIES, { type }, { requestPolicy: 'network-only' }))

  $: $content.variables = { type }
</script>

<Base loading={!$content.data} error={!!$content.error} works={$content.data?.work_summaries}>
  <TypeSelector slot="typeSelector" bind:type rowStart={4} colStart={3} />
</Base>
