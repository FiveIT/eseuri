<script>
  import { Auth0Context } from '@dopry/svelte-auth0'
  import { Router } from '@roxi/routify'
  import Window from '$/components/Window.svelte'
  import { routes } from '../.routify/routes'
</script>

<Window />

<Auth0Context
  domain={import.meta.env.VITE_AUTH0_DOMAIN}
  client_id={import.meta.env.VITE_AUTH0_CLIENT_ID}
  audience={import.meta.env.VITE_AUTH0_AUDIENCE}
  callback_url={window.location.origin}
  logout_url={window.location.origin}>
  <Router {routes} />
</Auth0Context>
