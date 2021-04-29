<script context="module" lang="ts">
  export const AUTHENTICATED = 0b0001
  export const REGISTERED = 0b0010
</script>

<script lang="ts">
  import { isAuthenticated, authError, isLoading } from '@tmaxmax/svelte-auth0'
  import { notify } from '$/components/Notifications.svelte'
  import * as user from '$/lib/user'
  import { goto } from '@roxi/routify'

  export let when: number
  export let redirect: string

  let current: number

  function check(what: number): boolean {
    return (current & what) === (when & what)
  }

  console.log('here')

  $: console.log({ current })

  $: if ($isLoading) {
    current = 0
  } else if ($authError) {
    current = 0

    notify({
      status: 'error',
      message: 'A apărut o eroare la autentificare',
      explanation: 'Încearcă să revii mai târziu, este o problemă de moment.',
    })
  } else {
    if ($isAuthenticated) {
      current |= AUTHENTICATED
    }

    user
      .isRegistered()
      .then(status => {
        if (status) {
          current |= REGISTERED
        }
      })
      .catch(err => {
        console.error(err)

        notify({
          status: 'error',
          message: 'A apărut o eroare internă, încearcă mai târziu.',
        })
      })
      .finally(() => {
        if (current !== when) {
          if (!check(AUTHENTICATED)) {
            notify({
              status: 'info',
              message: `Autentifică-te mai întâi pentru a avea acces la această resursă.`,
            })
          } else if (!check(REGISTERED)) {
            notify({
              status: 'info',
              message: `Înregistrează-te pentru a avea acces la această resursă.`,
              explanation: `Pentru a te înregistra, mergi în <a class="underline" href="/account/configure">Contul meu &gt; Configurare</a>, sau la <a class="underline" href="/register">Înregistrare</a>.`,
            })
          }

          $goto(redirect)
        }
      })
  }
</script>

{#if current === when}
  <slot />
{/if}
