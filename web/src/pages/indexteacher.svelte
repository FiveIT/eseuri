<script lang="ts" type="text/javascript">
  import { blue, orange, red, Layout, NavBig, window, LayoutContext } from '$/components'
  import Printer from '$/components/Printer.svelte'
  import type { BlobPropsInput, UserRevision } from '$/lib'
  import { unrevisedWorks, UnrevTypeTranslation } from '$/content'
  import { metatags } from '@roxi/routify'
  import { placeholderText, filterShadow } from '$/lib'

  metatags.title = 'Eseuri'

  let orangeBlobProps: BlobPropsInput
  $: orangeBlobProps = {
    scale: 1.8,
    x: 0,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput
  $: redBlobProps = {
    x: $window.width - red.width * 1.5,
    y: $window.height - red.height * 0.45,
    scale: 2,
    rotate: 180 + 26.7,
  }

  let blueBlobProps: BlobPropsInput
  $: blueBlobProps = {
    x: ($window.width - blue.width * 0.8) / 2,
    y: -blue.height * 0.635 + $window.height * 0.17,
    scale: 1.5,
  }

  let type: UserRevision = 'yours'
  const types: UserRevision[] = ['yours', 'anybody']
  $: ownWorks = unrevisedWorks.filter(w => w.teacher !== null)
  $: otherWorks = unrevisedWorks.filter(w => w.teacher === null)
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps} transition={{ y: 1000 }}>
  <NavBig />
  {#each types as t, i}
    <div class="col-start-{2 + 2 * i} col-span-2 row-start-4 flex flex-row m-auto my-auto">
      {#if t === 'yours'}<div
          class="font-sans text-xs rounded-full h-7 w-7 bg-red flex items-center justify-center text-white">
          {ownWorks.length}
        </div>{:else}
        <div
          class="font-sans text-xs rounded-full h-7 w-7 bg-gray flex items-center justify-center text-white">
          {otherWorks.length}
        </div>{/if}

      <button
        class="w-60 h-full font-sans text-xs antialiased"
        class:underline={type === t}
        on:click={() => (type = t)}>
        {UnrevTypeTranslation.ro[t].inarticulate.plural}</button>
    </div>
  {/each}
  {#if type == 'yours'}
    <LayoutContext let:theme>
      <div
        class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm col-start-1 col-end-7">
        {#if ownWorks.length}
          {#each ownWorks as work}
            <Printer {work} />
          {/each}
        {:else}
          <p
            class="col-start-2 place-self-center text-center text-md font-sans antialiased {placeholderText[
              theme
            ]} {filterShadow[theme]}">
            Liber!<br />Nicio lucrare.
          </p>
        {/if}
      </div>
    </LayoutContext>
  {:else}
    <LayoutContext let:theme>
      <div
        class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm col-start-1 col-end-7">
        {#if ownWorks.length}
          {#each otherWorks as work}
            <Printer {work} />
          {/each}
        {:else}
          <p
            class="col-start-2 place-self-center text-center text-md font-sans antialiased {placeholderText[
              theme
            ]} {filterShadow[theme]}">
            Liber!<br />Nicio lucrare.
          </p>
        {/if}
      </div>
    </LayoutContext>{/if}
</Layout>
