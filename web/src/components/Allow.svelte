<script lang="ts">
  import Loading from 'svelte-material-icons/Loading.svelte'

  import { isAuthenticated, authError, isLoading } from '@tmaxmax/svelte-auth0'
  import { notify } from '$/components/Notifications.svelte'
  import * as user from '$/lib/user'
  import { goto } from '@roxi/routify'

  import { fade } from 'svelte/transition'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
  } from '$/lib/globals'

  export let redirect: string

  export let dontNotify = false

  export let authenticated = false
  export let registered = false
  export let unregistered = false

  if (registered || unregistered) {
    authenticated = true

    if (registered === true && registered === unregistered) {
      throw new Error(
        'True values for both registered and unregistered flags are not allowed'
      )
    }
  }

  let showSlot = false
  let showLoading = unregistered
  let showLoadingHandle: ReturnType<typeof setTimeout> | undefined

  if (!showLoading) {
    showLoadingHandle = setTimeout(() => (showLoading = true), 500)
  }

  function clearLoading() {
    if (showLoadingHandle) {
      clearTimeout(showLoadingHandle)
    }
  }

  function bail(notif: Parameters<typeof notify>[0]) {
    clearLoading()

    if (!dontNotify) {
      notify(notif)
    }

    $goto(redirect)
  }

  function show() {
    clearLoading()

    showSlot = true
  }

  $: if ($authError) {
    bail({
      status: 'error',
      message: 'A apărut o eroare la autentificare',
      explanation: 'Încearcă să revii mai târziu, este o problemă de moment.',
    })
  } else if (!$isLoading) {
    if (!$isAuthenticated && authenticated) {
      bail({
        status: 'info',
        message: `Autentifică-te mai întâi pentru a avea acces la această resursă.`,
      })
    } else if (registered || unregistered) {
      user
        .isRegistered()
        .then(isRegistered => {
          if ((isRegistered && registered) || (!isRegistered && unregistered)) {
            show()

            return
          }

          if (registered) {
            bail({
              status: 'info',
              message: `Înregistrează-te pentru a avea acces la această resursă.`,
              explanation: `Pentru a te înregistra, mergi în <a class="underline" href="/account/configure">Contul meu &gt; Configurare</a>, sau la <a class="underline" href="/register">Înregistrare</a>.`,
            })
          } else {
            bail({
              status: 'info',
              message: 'Ești deja înregistrat',
            })
          }
        })
        .catch(() => {
          bail({
            status: 'error',
            message: 'A apărut o eroare internă, încearcă mai târziu.',
          })
        })
    } else {
      show()
    }
  }
</script>

{#if showSlot}
  <slot />
{:else if showLoading}
  <div
    class="flex flex-col space-md w-screen h-screen justify-center items-center bg-white"
    transition:fade={{ duration, easing }}>
    <p class="font-sans text-md antialiased text-gray">
      Te rugăm să aștepți...
    </p>

    <div class="animate-spin-a w-4em h-4em">
      <Loading color="var(--light-gray)" size="100%" />
    </div>
    <div class="animate-spin-b w-4em h-4em relative -top-4em">
      <Loading color="var(--gray)" size="100%" />
    </div>
  </div>
{/if}
