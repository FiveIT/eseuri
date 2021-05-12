<script lang="ts">
  import Base from './Base.svelte'
  import TeacherSelector from './TeacherSelector.svelte'
  import { UNREVISED_WORKS } from '$/graphql/queries'
  import { partition } from '$/lib'

  import { subscription, operationStore } from '@urql/svelte'

  export let id: number

  let hasNoTeacher = false
  let count: [number, number] | undefined

  const content = subscription(operationStore(UNREVISED_WORKS))

  $: [withTeacher, withNoTeacher] = partition($content.data?.works, w => w.teacher_id === id)
  $: withNoTeacher.sort((a, b) => +!!a.teacher_id - +!!b.teacher_id)
  $: count = !withTeacher || !withNoTeacher ? undefined : [withTeacher.length, withNoTeacher.length]

</script>

<Base
  loading={!$content.data}
  error={!!$content.error}
  works={hasNoTeacher ? withNoTeacher : withTeacher}>
  <TeacherSelector slot="typeSelector" bind:hasNoTeacher {count} />
</Base>
