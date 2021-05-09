<script context="module" lang="ts">
  import { notify } from '$/components'
  import client from '$/graphql/client'
  import { UPDATE_WORK_STATUS } from '$/graphql/queries'
  import type { UnrevisedWork } from '$/graphql/queries'
  import { getName, fromMutation, internalErrorNotification, formatDate } from '$/lib'

  import { firstValueFrom } from 'rxjs'
  import type { GotoHelper } from '@roxi/routify'

  function getMiddle(work: UnrevisedWork): string {
    if (work.essay) {
      return getName(work.essay.title.author)
    }

    return work.characterization.character.title.name
  }

  function getEnd(work: UnrevisedWork): string {
    const type = work.essay ? 'Eseu' : 'Caracterizare'
    const name = getName(work.user)

    return `${type} de ${name}`
  }

  async function onBeforeNavigate({ id: workID }: UnrevisedWork, goto: GotoHelper) {
    try {
      const { update_works_by_pk: value } = await firstValueFrom(
        fromMutation(client, UPDATE_WORK_STATUS, { workID, status: 'inReview' }).pipe(
          tap(v => console.log({ v }))
        )
      )

      if (!value) {
        notify({
          status: 'info',
          message: 'Lucrarea aceasta este în prezent revizuită de altcineva.',
          explanation:
            'Un alt profesor a intrat pe ea înaintea ta, iar tu ai accesat lucrarea exact înainte de a se actualiza meniul. Revizuiește altă lucrare!',
        })

        goto('/')
      } else {
        return true
      }
    } catch (err) {
      notify(internalErrorNotification)
    }
  }
</script>

<script lang="ts">
  import WorkBase from './internal/WorkBase.svelte'

  import { redirect } from '@roxi/routify'
  import { tap } from 'rxjs/operators'

  export let work: UnrevisedWork

  $: heading = (work.essay?.title || work.characterization!.character).name
  $: middle = getMiddle(work)
  $: end = getEnd(work)
  $: when =
    work.updated_at &&
    formatDate(new Date(work.updated_at + '+00:00'))
      .reverse()
      .join(' ')
</script>

<WorkBase
  href={`/work/${work.id}`}
  {heading}
  {middle}
  {end}
  showOverlay={!!when}
  onBeforeNavigate={() => onBeforeNavigate(work, $redirect)}>
  <p
    slot="overlay"
    class="w-full h-full flex items-center rounded-overlay font-sans font-bold text-sm antialiased text-center text-white">
    Ai început să revizuiești lucrarea {when}
  </p>
</WorkBase>

<style>
  p {
    background-color: rgba(0, 0, 0, 0.8);
  }
</style>
