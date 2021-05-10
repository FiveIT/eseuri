<script lang="ts">
  import { ModalFlex, notify } from '$/components'
  import client from '$/graphql/client'
  import { fromMutation, internalErrorNotification } from '$/lib'
  import { DELETE_ACCOUNT } from '$/graphql/queries'

  import { closeModal } from '@tmaxmax/renderless-svelte/src/Modal.svelte'
  import { AUTH0_CONTEXT_CLIENT_PROMISE, logout } from '@tmaxmax/svelte-auth0'
  import { getContext } from 'svelte'
  import { switchMap } from 'rxjs/operators'
  import { from, firstValueFrom } from 'rxjs'

  const auth0Client = getContext<any>(AUTH0_CONTEXT_CLIENT_PROMISE)

  function handler() {
    firstValueFrom(
      fromMutation(client, DELETE_ACCOUNT).pipe(switchMap(() => from(logout(auth0Client))))
    )
      .then(() =>
        notify({
          status: 'success',
          message: 'Contul tău a fost șters cu succes!',
        })
      )
      .catch(() => notify(internalErrorNotification))
      .finally(closeModal)
  }
</script>

<ModalFlex>
  <h1 class="w-full font-sans antialiased text-md text-white filter-shadow">
    Înainte de a-ți șterge definitiv contul
  </h1>
  <p class="w-full font-sans antialiased text-sm text-white filter-shadow">
    Prin ștergerea contului îți pierzi toate marcajele și asocierile cu elevii/profesorii tăi. De
    altfel, îți pierzi și statutul de profesor pe platformă, dacă e cazul, iar în situația în care
    îți creezi un cont nou va trebui să redepui o cerere pentru a fi profesor.<br />
    Lucrările tale nu vor fi șterse: acestea vor rămâne permanent pe platformă. Dacă totuși dorești să
    fie șterse <a href="mailto:tmaxmax@outlook.com" class="underline">contactează-ne pe email</a>.
  </p>
  <div class="grid auto-cols-layout grid-flow-col gap-x-md auto-rows-layout">
    <button
      on:click={closeModal}
      class="bg-white rounded w-full h-full flex items-center justify-center text-center text-blue filter-shadow font-sans text-sm antialiased p-xs leading-none">
      Anulez ștergerea
    </button>
    <button
      on:click={handler}
      class="rounded border-3 border-white w-full h-full flex items-center justify-center text-center text-white filter-shadow font-sans text-sm antialiased p-xs leading-none">
      Înțeleg, îmi șterg contul
    </button>
  </div>
</ModalFlex>
