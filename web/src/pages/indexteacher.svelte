<script lang="ts" type="text/javascript">
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import Layout from '$/components/Layout.svelte'
  import LoginButton from '$/components/LoginButton.svelte'
  import Logo from '$/components/Logo.svelte'
  import Printer from '$/components/Printer.svelte'
  import Buton from '$/components/NavButton.svelte'
  import Search from '$/components/SearchBar.svelte'
  import UploadButton from '$/components/UploadButton.svelte'
  import { store as window } from '$/components/Window.svelte'
  import type { BlobPropsInput, UserRevision, UnrevisedWork } from '$/types'
  import { unrevisedWorks, UnrevTypeTranslation } from '$/content'
  import { metatags } from '@roxi/routify'
  import { placeholderText, filterShadow } from '$/theme'
  import LayoutContext from '$/components/LayoutContext.svelte'

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
  function hasTeacher(work: UnrevisedWork): boolean {
    return work.teacher !== null
  }

  function noTeacher(work: UnrevisedWork): boolean {
    return work.teacher == null
  }
  let unrevtype: UserRevision = 'yours'
  const unrevtypes: UserRevision[] = ['yours', 'anybody']
  $: unrevised_works = unrevisedWorks.filter(unrevisedWorkswe =>
    hasTeacher(unrevisedWorkswe)
  )
  $: unrevised_genworks = unrevisedWorks.filter(unrevisedWorkswe =>
    noTeacher(unrevisedWorkswe)
  )

  let lg = unrevisedWorks.filter(unrevisedWorkswe =>
    hasTeacher(unrevisedWorkswe)
  ).length
  let lggen = unrevisedWorks.filter(unrevisedWorkswe =>
    noTeacher(unrevisedWorkswe)
  ).length
</script>

<Layout
  {orangeBlobProps}
  {redBlobProps}
  {blueBlobProps}
  transition={{ y: 1000 }}>
  <div
    class="row-start-1 row-span-1 col-start-1  col-span-1 my-auto select-none">
    <Logo />
  </div>
  <div class=" row-start-1 row-span-1 col-start-3 col-end-6 text-sm my-auto">
    <Search />
  </div>
  <div class="w-full h-full row-start-1 row-span-1 col-start-6 col-span-1">
    <LoginButton theme="white" />
  </div>
  <div class="col-start-4 col-end-5 row-start-2 w-full h-full text-sm my-auto ">
    <Buton enable={false} theme="white">Plagiat</Buton>
  </div>
  <div class="col-start-5 col-end-6 row-start-2 w-full h-full text-sm my-auto">
    <Buton enable={false} theme="white">Profesori</Buton>
  </div>
  <div class="col-span-1 col-start-6 row-span-1 row-start-3 place-self-center">
    <UploadButton />
  </div>
  {#each unrevtypes as t, i}
    <div
      class="col-start-{2 +
        2 * i} col-span-2 row-start-4 flex flex-row m-auto my-auto">
      {#if t === 'yours'}<div
          class="font-sans text-xs rounded-full h-7 w-7 bg-red flex items-center justify-center text-white">
          {lg}
        </div>{:else}
        <div
          class="font-sans text-xs rounded-full h-7 w-7 bg-gray flex items-center justify-center text-white">
          {lggen}
        </div>{/if}

      <button
        class="w-60 h-full font-sans text-xs antialiased"
        class:underline={unrevtype === t}
        on:click={() => (unrevtype = t)}>
        {UnrevTypeTranslation.ro[t].inarticulate.plural}</button>
    </div>
  {/each}
  {#if unrevtype == 'yours'}
    <LayoutContext let:theme>
      <div
        class="grid w-full h-full grid-cols-essays auto-rows-essays gap-x-lg gap-y-sm col-start-1 col-end-7">
        {#if unrevised_works.length}
          {#each unrevised_works as work}
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
        {#if unrevised_works.length}
          {#each unrevised_genworks as work}
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
