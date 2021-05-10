<script context="module" lang="ts">
  import type { TeacherAssociationStatus, Association } from '$/graphql/queries'

  type Props = Record<TeacherAssociationStatus, string>

  const borderColors: Props = {
    approved: 'border-white',
    pending: 'border-orange',
    rejected: 'border-red',
  }

  const overlayLabel: Props = {
    approved: '',
    pending: 'Cerere în așteptare',
    rejected: 'Cerere refuzată',
  }

  type Input = Omit<Association, 'initiator_id'>

  function getData(association: Input) {
    let user: NonNullable<typeof association.teacher>['user']

    if (association.teacher) {
      user = association.teacher.user
    } else {
      user = association.student!.user
    }

    const name = getName(user)
    const { email, school } = user

    return [name, email, school.short_name || school.name] as const
  }
</script>

<script lang="ts">
  import { getName } from '$/lib'
  import { Base } from './internal'
  import { DeleteButton } from '$/components'

  export let association: Input

  let name: string, email: string, school: string

  $: approved = association.status === 'approved'
  $: [name, email, school] = getData(association)
</script>

<div class="group relative">
  <Base showOverlay={!approved} darkBg={!approved} borderColor={borderColors[association.status]}>
    <div slot="heading" class="text-md mt-auto">
      {name}
    </div>
    <a
      slot="middle"
      href="mailto:{email}"
      class="text-workInfo leading-none my-auto underline break-words">{email}</a>
    <div slot="end" class="text-workInfo">{school}</div>
    <p
      slot="overlay"
      class="text-md w-full h-full flex items-center justify-center rounded-overlay font-sans antialiased text-center text-white select-none">
      {overlayLabel[association.status]}
    </p>
  </Base>
  {#if approved}
    <div class="absolute right-0.5em top-0.5em"><DeleteButton on:click /></div>
  {/if}
</div>

<style>
  p {
    background-color: rgba(0, 0, 0, 0.8);
  }
</style>
