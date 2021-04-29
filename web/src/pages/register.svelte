<script lang="ts">
  import SlimNav from '$/components/SlimNav.svelte'
  import Layout from '$/components/Layout.svelte'
  import LayoutContext from '$/components/LayoutContext.svelte'
  import Form from '$/components/form/Form.svelte'
  import Text from '$/components/form/Text.svelte'
  import Radio from '$/components/form/Radio.svelte'
  import Actions from '$/components/form/Actions.svelte'

  import { goto, metatags } from '@roxi/routify'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as window } from '$/components/Window.svelte'

  import type { BlobPropsInput, Role } from '$/types'
  import { roleTranslation } from '$/content'
  import type { Writable } from 'svelte/store'
  import { go } from '$/components/Link.svelte'

  import { REGISTER_USER } from '$/graphql/queries'
  import type { RegisterUser, Data, Vars } from '$/graphql/types'
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
    form.forEach((v, k) => console.log({ [k]: v }))

    try {
      await client
        .mutation<Data<RegisterUser>, Vars<RegisterUser>>(REGISTER_USER, {
          userID: 1,
          firstName: form.get('first_name')!.toString(),
          middleName: null,
          lastName: form.get('last_name')!.toString(),
          schoolID: parseInt(form.get('school')!.toString()),
        })
        .toPromise()
    } catch (err) {
      console.error(err)
    } finally {
      go('/', alive, $goto)
    }
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} blurBackground>
  <LayoutContext let:alive>
    <SlimNav logoOnly={true} />
    <Form
      name="register"
      {action}
      bind:formElement
      on:submit={() => onSubmit(alive)}>
      <span slot="legend">Completează-ți profilul</span>
      <Text name="last_name" placeholder="Scrie-ți aici numele de familie...">
        Numele tău
      </Text>
      <Text name="first_name" placeholder="Scrie-ți aici prenumele...">
        Prenumele tău
      </Text>
      <Text name="school" placeholder="Scrie-ți aici numele școlii...">
        Școala ta
      </Text>
      <Radio name="role" options={roles} displayModifier={translateRole}>
        Ocupația ta
      </Radio>
      <Actions slot="actions" submitValue="Sunt gata" />
    </Form>
  </LayoutContext>
</Layout>
