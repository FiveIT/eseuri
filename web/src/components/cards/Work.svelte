<script lang="ts">
  import type { WorkSummary } from '$/lib'

  import WorkBase from './internal/WorkBase.svelte'
  import { workTypeTranslation } from '$/lib'

  export let work: WorkSummary

  $: end = `${work.work_count} ${work.work_count > 19 ? ' de' : ''} ${
    workTypeTranslation.ro[work.type].inarticulate[work.work_count === 1 ? 'singular' : 'plural']
  }`
</script>

<WorkBase href={`/work/${work.type}/${work.url}`} heading={work.name} middle={work.creator} {end} />
