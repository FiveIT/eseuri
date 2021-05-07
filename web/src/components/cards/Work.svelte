<script lang="ts">
  import type { WorkSummary } from '$/lib'

  import Base from './internal/Base.svelte'
  import { workTypeTranslation } from '$/lib'
  import { Link } from '$/components'

  export let work: WorkSummary
</script>

<Link href={`/work/${work.type}/${work.url}`}>
  <Base>
    <div slot="heading" class="text-md mt-auto">{work.name}</div>
    <div slot="middle" class="text-workInfo leading-none my-auto">{work.creator}</div>
    <div slot="end" class="text-workInfo">
      {work.work_count}{work.work_count > 19 ? ' de' : ''}
      {workTypeTranslation.ro[work.type].inarticulate[
        work.work_count === 1 ? 'singular' : 'plural'
      ]}
    </div>
  </Base>
</Link>
