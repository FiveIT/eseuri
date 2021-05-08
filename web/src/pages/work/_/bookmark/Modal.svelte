<script context="module" lang="ts">
  const notification = {
    status: 'success',
    message: 'Marcaj creat cu succes, lucrarea este salvată!',
  } as const
</script>

<script lang="ts">
  import { Form, Text, ActionsModal } from '$/components'
  import type { SubmitFn } from '$/components'
  import { TRANSITION_EASING as easing } from '$/lib'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  import { fade } from 'svelte/transition'
  import { onMount } from 'svelte'
  import type { Work } from '..'

  export let work: Work

  let focus: () => void
  let elem: HTMLElement

  const onSubmit: SubmitFn = ({ body }) =>
    work
      .bookmark(body.get('name')!.toString())
      .then(closeModal)
      .then(() => notification)

  onMount(() => focus())
</script>

<div
  class="bg fixed top-0 left-0 w-full h-full flex justify-center items-center z-100"
  transition:fade={{ easing, duration: 50 }}>
  <div
    class="grid gap-x-md gap-y-sm px-md py-sm grid-cols-form auto-rows-layout bg-white rounded border-2px"
    bind:this={elem}
    on:blur={closeModal}>
    <Form name="bookmark" {onSubmit} bind:focus cols={1} rows={2}>
      <span slot="legend">Creează un marcaj</span>
      <Text name="name" placeholder="Scrie numele marcajului aici..." required>Nume</Text>
      <ActionsModal slot="actions" closeFn={closeModal}>Salvează lucrarea</ActionsModal>
    </Form>
  </div>
</div>

<style>
  .bg {
    background-color: rgba(0, 0, 0, 0.5);
  }
</style>
