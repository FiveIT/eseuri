<script lang="ts">
  import { isAuthenticated, authError, isLoading } from '@tmaxmax/svelte-auth0'
  import { notify, Spinner } from '.'
  import {
    TRANSITION_EASING as easing,
    TRANSITION_DURATION as duration,
    status,
    statusError,
  } from '$/lib'
  import type { Notification, Timeout } from '$/lib'

  import { onDestroy } from 'svelte'
  import { fade } from 'svelte/transition'
  import { redirect as goto } from '@roxi/routify'

  export let redirect: string

  export let dontNotify = false

  export let authenticated = false
  export let registered = false
  export let unregistered = false

  if (registered || unregistered) {
    authenticated = true

    if (registered === true && registered === unregistered) {
      throw new Error('True values for both registered and unregistered flags are not allowed')
    }
  }

  let showSlot = false
  let showLoading = unregistered
  let showLoadingHandle: Timeout | undefined

  if (!showLoading) {
    showLoadingHandle = setTimeout(() => (showLoading = true), 500)
  }

  function clear() {
    if (showLoadingHandle) {
      clearTimeout(showLoadingHandle)
    }
  }

  onDestroy(clear)

  function bail(notification: Notification) {
    if (!dontNotify || notification.status === 'error') {
      notify(notification)
    }

    $goto(redirect)
  }

  function show() {
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
      if ($status) {
        if (($status.isRegistered && registered) || (!$status.isRegistered && unregistered)) {
          show()
        } else if (registered) {
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
      } else if ($statusError) {
        console.error({ allowError: $statusError })

        bail({
          status: 'error',
          message: 'A apărut o eroare internă, încearcă mai târziu.',
        })
      }
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
    <Spinner message="Te rugăm să aștepți..." />
  </div>
{/if}
