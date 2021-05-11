<script lang="ts">
  import Base from './Base.svelte'
  import TeacherSelector from './TeacherSelector.svelte'
  import { UNREVISED_WORKS } from '$/graphql/queries'

  import { subscription, operationStore } from '@urql/svelte'

  export let id: number

  let hasNoTeacher = false
  let count: [number, number] | undefined

  const content = subscription(operationStore(UNREVISED_WORKS))

  $: withTeacher = $content.data?.works.filter(w => w.teacher_id === id)
  $: withNoTeacher = $content.data?.works.filter(w => w.teacher_id === null)
  $: count = !withTeacher || !withNoTeacher ? undefined : [withTeacher.length, withNoTeacher.length]
</script>

<Base
  loading={!$content.data}
  error={!!$content.error}
  works={hasNoTeacher ? withNoTeacher : withTeacher}>
  <TeacherSelector slot="typeSelector" bind:hasNoTeacher {count} />
</Base>
