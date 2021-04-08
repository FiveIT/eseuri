<script lang="ts">
  import { Auth0Context } from '@tmaxmax/svelte-auth0'
  import { Router } from '@roxi/routify'
  import Window from '$/components/Window.svelte'
  import { routes } from '../.routify/routes'

  const domain = import.meta.env.VITE_AUTH0_DOMAIN as string
  const client_id = import.meta.env.VITE_AUTH0_CLIENT_ID as string
  const audience = import.meta.env.VITE_AUTH0_AUDIENCE as string
  const callback_url = window.location.origin
  const logout_url = window.location.origin
</script>

<Window />

<Auth0Context {domain} {client_id} {audience} {callback_url} {logout_url}>
  <Router {routes} />
</Auth0Context>
