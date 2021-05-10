<script lang="ts">
  import {
    Layout,
    LayoutContext,
    NavSlim,
    Form,
    Radio,
    Select,
    Spinner,
    Actions,
    defaultSubmitFn,
    orange,
    red,
    window,
    notify,
    go,
  } from '$/components'
  import type { SubmitArgs } from '$/components'

  import { goto, metatags, params, redirect, url } from '@roxi/routify'

  import { getContext } from 'svelte'
  import { from } from 'rxjs'
  import { tap } from 'rxjs/operators'

  import type { Context } from '../upload.svelte'
  import { contextKey } from '../upload.svelte'
  import { getRequestedTeachers } from '.'

  import type { BlobPropsInput, WorkType } from '$/lib'
  import { workTypeTranslation, getName } from '$/lib'

  import { operationStore, query } from '@urql/svelte'
  import { TITLES, CHARACTERS } from '$/graphql/queries'
  import type { Writable } from 'svelte/store'

  metatags.title = 'Încarcă o lucrare - Eseuri'

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

  const action = `${import.meta.env.VITE_FUNCTIONS_URL}/upload`
  const workTypes = ['essay', 'characterization'] as const
  const translateWorkType = (w: WorkType) => workTypeTranslation.ro[w].inarticulate.singular

  let currentWorkType: WorkType = $params.type
  let currentWorkID = parseInt($params.id) || undefined

  const ctx = getContext<Context>(contextKey)

  function removeFile() {
    ctx.file = null
  }

  const submit = (alive: Writable<boolean>, args: SubmitArgs) => {
    args.body.append('file', ctx.file!)

    return from(defaultSubmitFn(args)).pipe(
      tap(() => {
        removeFile()
        go('/', alive, $goto)
      })
    )
  }

  const message = 'Lucrarea ta a fost încărcată cu succes!'
  const explanation = `Va fi publică în scurt timp, după ce a fost revizuită de un profesor.`

  const teachers = getRequestedTeachers()
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
  <LayoutContext let:alive>
    {#if !ctx || ctx.file === null}
      {go('/upload', alive, $redirect)}
    {:else}
      <NavSlim on:navigate={removeFile} />
      <Form
        name="work"
        {action}
        {message}
        {explanation}
        formenctype="multipart/form-data"
        onSubmit={args => submit(alive, args)}>
        <span slot="legend">Despre lucrare</span>
        <Radio
          name="type"
          options={workTypes}
          displayModifier={translateWorkType}
          bind:selected={currentWorkType}>Tip</Radio>
        <Select
          name="subject"
          placeholder="Alege {currentWorkType === 'essay' ? 'titlul' : 'numele personajului'}..."
          options={subjects[currentWorkType] || []}
          mapper={v => v.id}
          display={v => v.name}
          bind:value={currentWorkID}
          required>
          {currentWorkType === 'essay' ? 'Titlu' : 'Caracter'}
        </Select>
        {#if $teachers === null}
          <p class="font-sans text-sm antialiased text-gray">
            A apărut o eroare la obținerea asocierilor tale
          </p>
        {:else if $teachers}
          {#if $teachers.length}
            <Select
              name="requestedTeacher"
              placeholder="Opțional: alege cine va revizui lucrarea"
              options={$teachers}
              mapper={({ teacher }) => teacher.user.id}
              display={({ teacher }) => getName(teacher.user)}>Profesor pentru revizuire</Select>
          {/if}
        {:else}
          <Spinner longDuration={null} />
        {/if}
        <Actions slot="actions" abortHref={$url('/upload', $params)} on:navigate={removeFile}
          >Publică</Actions>
      </Form>
    {/if}
  </LayoutContext>
</Layout>
