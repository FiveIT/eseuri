<script lang="ts">
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import SlimNav from '$/components/SlimNav.svelte'
  import NavButton from '$/components/NavButton.svelte'

  import Form from '$/components/form/Form.svelte'
  import Radio from '$/components/form/Radio.svelte'
  import Text from '$/components/form/Text.svelte'
  import Submit from '$/components/form/Submit.svelte'

  import { goto } from '@roxi/routify'

  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as window } from '$/components/Window.svelte'

  import { getContext } from 'svelte'

  import type { Context } from './upload.svelte'
  import { contextKey } from './upload.svelte'
  import { go } from '$/components/Link.svelte'

  import type { BlobPropsInput, WorkType } from '$/types'
  import content, { workTypeTranslation } from '$/content'
  import type { Writable } from 'svelte/store'

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
  const workTypes: WorkType[] = ['essay', 'characterization']
  const translateWorkType = (w: WorkType) =>
    workTypeTranslation.ro[w].inarticulate.singular

  let currentWorkType: WorkType

  $: suggestions = content
    .filter(({ type }) => type === currentWorkType)
    .map(n => n.name)

  let formElement: HTMLFormElement

  const ctx = getContext<Context>(contextKey)

  function onSubmit(alive: Writable<boolean>) {
    const form = new FormData(formElement)
    form.append('file', ctx.file!)
    form.forEach((v, k) => console.log({ [k]: v }))
    ctx.file = null
    go('/', alive, $goto)
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground={true}>
  <LayoutContext let:alive>
    {#if !ctx || ctx.file === null}
      {go('/upload', alive, $goto)}
    {:else}
      <SlimNav />
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
        <Text
          name="name"
          placeholder="Scrie aici {currentWorkType === 'essay'
            ? 'titlul'
            : 'numele personajului'}..."
          {suggestions}>
          {currentWorkType === 'essay' ? 'Titlu' : 'Caracter'}
        </Text>
        <div
          slot="actions"
          class="row-end-7 col-start-3 col-span-2 grid auto-cols-layout grid-flow-col gap-x-md">
          <Submit value="Publică" formenctype="multipart/form-data" />
          <NavButton href="/upload">Înapoi</NavButton>
        </div>
      </Form>
    {/if}
  </LayoutContext>
</Layout>
