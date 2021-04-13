<script lang="ts">
  import { metatags } from '@roxi/routify'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { onMount } from 'svelte'
  import Buton from '$/components/buton.svelte'
  import Search from '$/components/search_bar.svelte'
  import UploadButton from '$/components/upload_button.svelte'
  import Essay from '$/components/essay.svelte'
  import Logo from '$/components/logo.svelte'
  import { fly } from 'svelte/transition'
  import LoginButton from '$/components/login_button.svelte'
  let eseuri = [
    { name: 'Ion', scriitor: 'Liviu Rebreanu' },
    { name: 'O scrisoare gasita', scriitor: 'I.L. Caragiale' },
    {
      name: 'Ultima noapte de dragoste. Intaia noapte de razboi',
      scriitor: 'Camil Petrescu',
    },
    { name: 'Moara cu noroc', scriitor: 'Ioan Slavici' },
    { name: 'Morometii', scriitor: 'Marin Preda' },
    { name: 'Povestea lui Harap-Alb', scriitor: 'Ion Creanga' },
    { name: 'La tiganci', scriitor: 'Mircea Eliade' },
    { name: 'Baltagul', scriitor: 'Mihail Sadoveanu' },
    { name: 'In gradina Ghetsemani', scriitor: 'Vasile Voiculescu' },
    { name: 'Creanga de aur', scriitor: 'Liviu Rebreanu' },
  ]
  let caracterizari = [
    { name: 'Ion', scriitor: 'Liviu Rebreanu' },
    { name: 'O scrisoare pierduta', scriitor: 'I.L. Caragiale' },
    {
      name: 'Ultima noapte de dragoste. Intaia noapte de razboi',
      scriitor: 'Camil Petrescu',
    },
    { name: 'Moara cu noroc', scriitor: 'Ioan Slavici' },
  ]
  let eseuri_chosen = true
  function show_eseuri() {
    eseuri_chosen = true
  }
  function show_caracterizari() {
    eseuri_chosen = false
  }
  metatags.title = 'Eseuri'
  let mounted: boolean = false
  onMount(() => {
    $orange = {
      x: 0,
      y: $window.height - orange.height,
      scale: 1.8,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
      zIndex: -1,
    }
    $red = {
      x: $window.width - red.width * 1.5,
      y: $window.height - red.height * 0.45,
      scale: 2,
      rotate: 180 + 26.7,
      flip: {
        x: 1,
        y: 0,
      },
      zIndex: -1,
    }
    $blue = {
      x: ($window.width - blue.width * 0.8) / 2,
      y: -blue.height * 0.635 + $window.height * 0.17,
      scale: 1.5,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
      zIndex: -1,
    }
    mounted = true
  })
  let alive = true
  $: if (mounted) {
    $orange.x = 0
    $orange.y = $window.height - orange.height
    $red.x = $window.width - red.width * 1.5
    $red.y = $window.height - red.height * 0.45
    $blue.x = ($window.width - blue.width * 0.8) / 2
    $blue.y = -blue.height * 0.635 + $window.height * 0.17
  }
</script>

{#if alive}
  <div
    class="w-full over flex flex-row justify-center flex-wrap relative scrollbar-window-padding ">
    <div
      class=" z-0 relative mt-xlg  "
      transition:fly={{ y: -$window.height, duration: 300 }}>
      <div
        class="bg-transparent auto-rows-layout  max-w-layout  grid-cols-layout relative w-full grid gap-x-md gap-y-sm mx-auto">
        <div class="row-start-1 row-span-1 col-start-1  col-span-1 my-auto">
          <Logo />
        </div>
        <div
          class=" row-start-1 row-span-1 col-start-3 col-end-6 text-sm my-auto">
          <Search
            page_name={undefined}
            isAtHome={true}
            isBig={false}
            bind:alive />
        </div>
        <div
          class="w-full h-full row-start-1 row-span-1 col-start-6 col-span-1">
          <LoginButton white={true} />
        </div>
        <div
          class="col-start-4 col-end-5 row-start-2 w-full h-full text-sm my-auto ">
          <Buton white={true} bind:alive link="./">Plagiat</Buton>
        </div>
        <div
          class="col-start-5 col-end-6 row-start-2 w-full h-full text-sm my-auto">
          <Buton white={true} bind:alive link="./">Profesori</Buton>
        </div>
        <div
          class=" col-start-3 col-end-4 row-start-4 w-full h-full m-auto my-auto ">
          <button
            class=" w-full h-full  bg-white bg-opacity-0 focus:outline-none outline-none focus:underline  font-sans text-sm "
            on:click={show_eseuri}>Eseuri</button>
        </div>
        <div
          class="col-start-4 col-end-5 row-start-4 w-full h-full m-auto my-auto">
          <button
            class="bg-white w-full h-full bg-opacity-0  focus:outline-none focus:underline  my-auto font-sans text-sm "
            on:click={show_caracterizari}>Caracterizari</button>
        </div>
        <div class="col-span-1 col-start-6 row-span-1 row-start-3 mx-auto">
          <UploadButton link={'./upload'} bind:alive />
        </div>
        {#if eseuri_chosen == true}
          <div
            class="grid-cols-essays auto-rows-essays max-w-layout grid relative fixed grid row-start-5  col-start-1 col-end-7 overflow-x-visible w-full h-full gap-x-lg gap-y-sm "
            transition:fly={{ x: -100, duration: 100 }}>
            {#each eseuri as { name, scriitor }}
              <div rel="preload" class="h-full w-full">
                <Essay bind:alive {name} {scriitor} works={0} white={false} />
              </div>
            {/each}
          </div>
        {:else}
          <div
            class="grid-cols-essays auto-rows-essays max-w-layout grid relative fixed grid row-start-5  col-start-1 col-end-7 overflow-x-visible w-full h-full gap-x-lg gap-y-sm "
            transition:fly={{ x: 100, duration: 100 }}>
            {#each caracterizari as { name, scriitor }}
              <Essay bind:alive {name} {scriitor} works={0} white={false} />
            {/each}
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}
