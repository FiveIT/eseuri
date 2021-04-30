<script lang="ts">
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import SlimNav from '$/components/SlimNav.svelte'

  import Form from '$/components/form/Form.svelte'
  import Radio from '$/components/form/Radio.svelte'
  import Select from '$/components/form/Select.svelte'
  import Actions from '$/components/form/Actions.svelte'

  import { goto } from '@roxi/routify'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as window } from '$/components/Window.svelte'
  import Notifications, { notify } from '$/components/Notifications.svelte'

  import { getContext } from 'svelte'

  import type { Context } from './upload.svelte'
  import { contextKey } from './upload.svelte'
  import { go } from '$/components/Link.svelte'

  import type { BlobPropsInput, WorkType } from '$/lib/types'
  import { workTypeTranslation } from '$/lib/content'
  import type { Writable } from 'svelte/store'

  import client from '$/graphql/client'

  import { pipe, map, toArray, fromArray, mergeAll } from 'wonka'

  import { TITLES, CHARACTERS } from '$/graphql/queries'
  import type { Titles, Characters, Data } from '$/graphql/types'

  const titles = pipe(
    client.query<Data<Titles>>(TITLES),
    map(res => fromArray(res.error ? [] : res.data!.titles)),
    mergeAll,
    toArray
  )

  const characters = pipe(
    client.query<Data<Characters>>(CHARACTERS),
    map(res => fromArray(res.error ? [] : res.data!.characters)),
    mergeAll,
    toArray
  )

  const subjects = {
    essay: titles,
    characterization: characters,
  } as const

  const failedSubjectQuery = Object.values(subjects).some(s => s.length === 0)
  if (failedSubjectQuery) {
    notify({
      status: 'error',
      message: 'Nu s-au putut obține subiectele pentru lucrări',
      explanation: `Reîmprospătează pagina și dacă tot nu merge încearcă mai târziu`,
    })
  }

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    x: 0,
    y: $window.height - orange.height,
    scale: 1.8,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    x: $window.width - red.width * 1,
    y: 0,
    scale: 2,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: $window.width * 0.65,
    y: $window.height * 0.9,
    scale: 1.5,
  }

  const action = import.meta.env.FUNCTIONS_URL as string
  const workTypes = ['essay', 'characterization'] as const
  const translateWorkType = (w: WorkType) =>
    workTypeTranslation.ro[w].inarticulate.singular

  let currentWorkType: WorkType

  let formElement: HTMLFormElement

  const ctx = getContext<Context>(contextKey)

  function removeFile() {
    ctx.file = null
  }

  function onSubmit(alive: Writable<boolean>) {
    const form = new FormData(formElement)
    form.append('file', ctx.file!)
    form.forEach((v, k) => console.log({ [k]: v }))
    removeFile()
    go('/', alive, $goto)
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
  <LayoutContext let:alive>
    {#if !ctx || ctx.file === null}
      {go('/upload', alive, $goto)}
    {:else}
      <SlimNav on:navigate={removeFile} />
      <Form
        name="work"
        {action}
        bind:formElement
        on:submit={() => onSubmit(alive)}>
        <span slot="legend">Despre lucrare</span>
        <Radio
          name="type"
          options={workTypes}
          displayModifier={translateWorkType}
          bind:selected={currentWorkType}>
          Tip
        </Radio>
        <Select
          name="subject"
          placeholder="Alege {currentWorkType === 'essay'
            ? 'titlul'
            : 'numele personajului'}..."
          options={subjects[currentWorkType]}
          required>
          {currentWorkType === 'essay' ? 'Titlu' : 'Caracter'}
        </Select>
        <Actions
          slot="actions"
          formenctype="multipart/form-data"
          submitValue="Publică"
          on:navigate={removeFile} />
      </Form>
    {/if}
    <Notifications />
  </LayoutContext>
</Layout>
