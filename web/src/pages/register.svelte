<script lang="ts">
  import SlimNav from '$/components/SlimNav.svelte'
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import Form from '$/components/form/Form.svelte'
  import Text from '$/components/form/Text.svelte'
  import Radio from '$/components/form/Radio.svelte'
  import Actions from '$/components/form/Actions.svelte'
  import Allow from '$/components/Allow.svelte'
  import Notifications, { notify } from '$/components/Notifications.svelte'

  import { goto, metatags } from '@roxi/routify'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as window } from '$/components/Window.svelte'

  import type { BlobPropsInput, Role } from '$/lib/types'
  import { roleTranslation } from '$/lib/content'
  import type { Writable } from 'svelte/store'
  import { go } from '$/components/Link.svelte'

  import { REGISTER_USER } from '$/graphql/queries'
  import type { RegisterUser, Vars } from '$/graphql/types'
  import client from '$/graphql/client'

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

  metatags.title = 'Înregistrare'

  const roles: Role[] = ['student', 'teacher']
  const translateRole = (r: Role) => roleTranslation.ro[r].inarticulate.singular

  const action = import.meta.env.FUNCTIONS_URL as string
  let formElement: HTMLFormElement

  async function onSubmit(alive: Writable<boolean>) {
    const form = new FormData(formElement)

    try {
      const vars: Vars<RegisterUser> = {
        firstName: form.get('first_name')!.toString(),
        middleName: form.get('middle_name')!.toString() || null,
        lastName: form.get('last_name')!.toString(),
        schoolID: parseInt(form.get('school')!.toString() || ''),
      }

      console.log({ vars })

      const res = await client.mutation(REGISTER_USER, vars).toPromise()

      if (res.error) {
        throw res.error
      }

      console.log(res.data)

      go('/', alive, $goto)

      notify({
        status: 'success',
        message: 'Te-ai înregistrat cu succes!',
      })
    } catch (err) {
      console.error(err)
    }
  }
</script>

<Allow unregistered redirect="/" dontNotify>
  <Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
    <LayoutContext let:alive>
      <SlimNav logoOnly />
      <Form
        name="register"
        {action}
        bind:formElement
        on:submit={() => onSubmit(alive)}>
        <span slot="legend">Completează-ți profilul</span>
        <Text
          name="last_name"
          placeholder="Scrie-ți aici numele de familie..."
          required>
          Numele tău
        </Text>
        <Text name="first_name" placeholder="Scrie-l aici..." required>
          Primul prenume
        </Text>
        <Text name="middle_name" placeholder="Scrie-l aici...">
          Al doilea prenume
        </Text>
        <Text name="county" placeholder="Scrie aici judetul scolii..." required>
          Județul școlii tale
        </Text>
        <Text name="school" placeholder="Scrie aici numele școlii..." required>
          Școala ta
        </Text>
        <Radio name="role" options={roles} displayModifier={translateRole}>
          Ocupația ta
        </Radio>
        <Actions slot="actions" submitValue="Sunt gata" />
      </Form>
      <Notifications />
    </LayoutContext>
  </Layout>
</Allow>
