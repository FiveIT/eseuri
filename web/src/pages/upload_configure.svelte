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
  import { uploadWork, RequestError } from '$/lib/user'
  import type { Writable } from 'svelte/store'

  import { operationStore, query } from '@urql/svelte'
  import { TITLES, CHARACTERS } from '$/graphql/queries'

  const titles = query(operationStore(TITLES))
  const characters = query(operationStore(CHARACTERS))

  $: subjects = {
    essay: $titles.data?.titles || [],
    characterization: $characters.data?.characters || [],
  }

  $: if ($titles.error || $characters.error) {
    notify({
      status: 'error',
      message: 'Nu s-au putut obține subiectele pentru lucrări.',
      explanation: `Reîncearcă mai târziu să încarci o lucrare, problema va fi în curând rezolvată!`,
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

  async function onSubmit(alive: Writable<boolean>) {
    try {
      const form = new FormData(formElement)
      form.append('file', ctx.file!)

      await uploadWork(form)

      notify({
        status: 'success',
        message: 'Lucrarea ta a fost încărcată cu succes!',
        explanation: `Va fi publică în scurt timp, după ce a fost revizuită de un profesor.`,
      })
    } catch (err) {
      if (err instanceof RequestError) {
        notify({
          status: 'error',
          message: err.message,
          explanation: err.explanation,
        })
      } else {
        console.error(err)

        notify({
          status: 'error',
          message: 'Ceva neașteptat s-a întâmplat, încearcă mai târziu.',
        })
      }
    }

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
          options={subjects[currentWorkType] || []}
          mapper={v => v.id}
          display={v => v.name}
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
