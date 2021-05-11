<script context="module" lang="ts">
  const notification = {
    status: 'success',
    message: 'Marcaj creat cu succes, lucrarea este salvată!',
  } as const
</script>

<script lang="ts">
  import { Form, Text, ActionsModal, ModalGrid } from '$/components'
  import type { SubmitFn } from '$/components'
  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  import { onMount } from 'svelte'
  import type { Work } from '..'

  export let work: Work

  let focus: () => void

  const onSubmit: SubmitFn = ({ body }) =>
    work
      .bookmark(body.get('name')!.toString())
      .then(closeModal)
      .then(() => notification)

  onMount(() => focus())
</script>

<ModalGrid>
  <Form name="bookmark" {onSubmit} bind:focus cols={1} rows={2}>
    <span slot="legend">Creează un marcaj</span>
    <Text name="name" placeholder="Scrie numele marcajului aici..." required>Nume</Text>
    <ActionsModal slot="actions" closeFn={closeModal}>Salvează lucrarea</ActionsModal>
  </Form>
</ModalGrid>
