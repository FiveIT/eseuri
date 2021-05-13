<script lang="ts">
  import { self, statusError } from '$/lib'
  import Error from './_/configure/Error.svelte'
  import Form from './_/configure/Form.svelte'
  import Spinner from './_/configure/Spinner.svelte'
  import Section from './_/configure/Section.svelte'
  import Header from './_/configure/Header.svelte'
  import TeacherRequest from './_/configure/TeacherRequest.svelte'
  import DeleteAccountModal from './_/configure/DeleteAccountModal.svelte'

  import { border, text } from '$/lib'
  import { LayoutContext } from '$/components'

  import { Auth0LogoutButton } from '@tmaxmax/svelte-auth0'
  import Modal, { openModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

  $: user = $self

</script>

<LayoutContext let:theme>
  <div class="row-span-6 col-span-3 space-y-sm">
    <Section>
      <Header>Acțiuni cont</Header>
      <TeacherRequest />
      <Auth0LogoutButton
        class="font-sans text-sm rounded {border.color[theme]} {border.all[theme]} leading-none">
        Deconectează-te de la contul curent
      </Auth0LogoutButton>
    </Section>
    <Section>
      <Header>Zona periculoasă</Header>
      <button
        on:click={() => openModal(true)}
        class="rounded {border.color[theme]} {border.all[
          theme
        ]} hover:(bg-red border-red) focus-visible:(bg-red border-red) transition-all duration-100 ease-out font-sans text-sm antialiased leading-none">
        Șterge-ți contul
      </button>
    </Section>
    {#if user && user.found}
      <Section>
        <p
          class="{text[
            theme
          ]} text-sm font-sans antialiased text-center w-full h-full flex items-center justify-center">
          Adresa ta de email:<br />{user.user.email}
        </p>
      </Section>
    {/if}
  </div>
  {#if user}
    {#if user.found}
      <Form user={user.user} />
    {:else}
      <Error>Ceva ciudat s-a întâmplat, reîncarcă pagina și vezi dacă merge!</Error>
    {/if}
  {:else if $statusError}
    <Error>Nu am putut obține datele de utilizator, revino mai târziu.</Error>
  {:else}
    <Spinner />
  {/if}
  <Modal let:payload>
    {#if payload}
      <DeleteAccountModal />
    {/if}
  </Modal>
</LayoutContext>
