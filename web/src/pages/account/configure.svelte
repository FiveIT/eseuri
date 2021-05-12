<script lang="ts">
  import { self, statusError } from '$/lib'
  import Error from './_/configure/Error.svelte'
  import Form from './_/configure/Form.svelte'
  import Spinner from './_/configure/Spinner.svelte'
  import Section from './_/configure/Section.svelte'
  import Header from './_/configure/Header.svelte'
  import TeacherRequest from './_/configure/TeacherRequest.svelte'
  import DeleteAccountModal from './_/configure/DeleteAccountModal.svelte'

  import { border } from '$/lib'
  import { LayoutContext } from '$/components'

  import { Auth0LogoutButton } from '@tmaxmax/svelte-auth0'
  import Modal, { openModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'

</script>

<LayoutContext let:theme>
  <div class="row-span-5 col-span-3 space-y-sm">
    <Section>
      <Header>Acțiuni cont</Header>
      <TeacherRequest />
      <Auth0LogoutButton
        class="font-sans text-sm rounded {border.color[theme]} {border.all[theme]}">
        Deconectează-te de la contul curent
      </Auth0LogoutButton>
    </Section>
    <Section>
      <Header>Zona periculoasă</Header>
      <button
        on:click={() => openModal(true)}
        class="rounded {border.color[theme]} {border.all[
          theme
        ]} hover:(bg-red border-red) transition-all duration-100 ease-out font-sans text-sm antialiased">
        Șterge-ți contul
      </button>
    </Section>
  </div>
  {#if $self}
    {#if $self.found}
      <Form user={$self.user} />
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
