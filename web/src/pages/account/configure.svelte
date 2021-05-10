<script lang="ts">
  import { self } from '$/lib'
  import Error from './_/configure/Error.svelte'
  import Form from './_/configure/Form.svelte'
  import Spinner from './_/configure/Spinner.svelte'

  const formData = self()

</script>

<section class="row-span-3 col-span-3 bg-white" />
<section class="row-span-2 row-start-4 col-span-3 bg-white" />
{#if $formData === null}
  <Error>Nu am putut obține datele de utilizator, revino mai târziu.</Error>
{:else if $formData}
  {#if $formData.found}
    <Form user={$formData.user} />
  {:else}
    <Error>Ceva ciudat s-a întâmplat, reîncarcă pagina și vezi dacă merge!</Error>
  {/if}
{:else}
  <Spinner />
{/if}
