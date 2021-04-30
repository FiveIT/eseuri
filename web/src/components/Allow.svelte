<script lang="ts">
  import { isAuthenticated, authError, isLoading } from '@tmaxmax/svelte-auth0'
  import { notify } from '$/components/Notifications.svelte'
  import * as user from '$/lib/user'
  import { goto } from '@roxi/routify'

  export let redirect: string

  export let authenticated = false
  export let registered = false

  if (registered) {
    authenticated = true
  }

  function bail(notif: Parameters<typeof notify>[0]) {
    notify(notif)

    $goto(redirect)
  }

  let show = false

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
    } else if (registered) {
      user
        .isRegistered()
        .then(isRegistered => {
          if (isRegistered && registered) {
            show = true

            return
          }

          bail({
            status: 'info',
            message: `Înregistrează-te pentru a avea acces la această resursă.`,
            explanation: `Pentru a te înregistra, mergi în <a class="underline" href="/account/configure">Contul meu &gt; Configurare</a>, sau la <a class="underline" href="/register">Înregistrare</a>.`,
          })
        })
        .catch(err => {
          console.error(err)

          bail({
            status: 'error',
            message: 'A apărut o eroare internă, încearcă mai târziu.',
          })
        })
    } else {
      show = true
    }
  }
</script>

{#if show}
  <slot />
{/if}
