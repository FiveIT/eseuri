<script context="module" lang="ts">
  import type { Association } from '$/graphql/queries'
  import client from '$/graphql/client'
  import { RESOLVE_ASSOCIATION_REQUEST, DELETE_ASSOCIATION } from '$/graphql/queries'
  import { notify } from '$/components'
  import { fromMutation, internalErrorNotification, getName } from '$/lib'

  function user(assoc: Association) {
    return assoc.student ? assoc.student.user : assoc.teacher.user
  }

  function id(assoc: Association) {
    return user(assoc).id
  }

  function resolve({ initiator_id: initiatorID }: Association, approve: boolean) {
    const status = approve ? 'approved' : 'rejected'

    fromMutation(client, RESOLVE_ASSOCIATION_REQUEST, { initiatorID, status }).subscribe({
      next(result) {
        console.log(result)

        notify({
          status: 'success',
          message: 'Răspunsul a fost trimis cu succes!',
        })
      },
      error() {
        notify(internalErrorNotification)
      },
    })
  }

  function remove(assoc: Association) {
    fromMutation(client, DELETE_ASSOCIATION, { id: id(assoc) }).subscribe({
      next(result) {
        console.log(result)

        notify({
          status: 'success',
          message: `Nu mai ești asociat cu ${getName(user(assoc))}!`,
        })
      },
      error() {
        notify(internalErrorNotification)
      },
    })
  }
</script>

<script lang="ts">
  import {
    InitiateAssociation,
    IncomingAssociation,
    Association as Assoc,
    Spinner,
  } from '$/components'
  import AssociationModal from './associations/Modal.svelte'

  import { ASSOCIATIONS } from '$/graphql/queries'
  import { subscription, operationStore } from '@urql/svelte'
  import type { Role } from '$/lib'

  import Modal from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  export let userID: number
  export let role: Role

  const content = subscription(
    operationStore(ASSOCIATIONS, { userID, teacher: role === 'teacher' })
  )
  $: $content.variables = { userID, teacher: role === 'teacher' }
  $: if ($content.error) {
    notify({
      ...internalErrorNotification,
      message: 'Nu s-au putut obține asocierile.',
    })
  }
  $: data = $content.data?.teacher_student_associations.map(v => ({
    ...v,
    id: id(v),
  }))
</script>

{#if data}
  <InitiateAssociation />
  {#each data as assoc (assoc.id)}
    {#if assoc.status === 'pending' && assoc.initiator_id !== userID}
      <IncomingAssociation
        user={user(assoc)}
        on:response={({ detail }) => resolve(assoc, detail)} />
    {:else}
      <Assoc association={assoc} on:click={() => remove(assoc)} />
    {/if}
  {/each}
  <Modal let:payload={userID}>
    {#if userID}
      <AssociationModal {userID} />
    {/if}
  </Modal>
{:else if !$content.error}
  <div class="col-start-2 flex items-center justify-center h-full">
    <Spinner />
  </div>
{/if}
