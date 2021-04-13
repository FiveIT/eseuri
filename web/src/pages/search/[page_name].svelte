<script lang="ts">
  import Essay from '$/components/essay.svelte'
  import Link from '$/components/link.svelte'
  import LoginButton from '$/components/login_button.svelte'
  import Logo from '$/components/logo.svelte'
  import Buton from '$/components/buton.svelte'
  import UploadButton from '$/components/upload_button.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import Search from '$/components/search_bar.svelte'
  import { onMount } from 'svelte'
  import { fly } from 'svelte/transition'
  let eseuri = [
    { name: 'Ion', scriitor: 'Liviu Rebreanu' },
    { name: 'O scrisoare pierduta', scriitor: 'I.L. Caragiale' },
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
  let mounted: boolean = false
  onMount(() => {
    $orange = {
      x: -orange.width * 1.4,
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
      x: $window.width + red.width * 0.6,
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
      scale: 17,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
      zIndex: -1,
    }
    mounted = true
  })
  export let page_name: string

  let alive = true
  $: if (mounted) {
    $orange.x = -orange.width * 1.4
    $orange.y = $window.height - orange.height
    $red.x = $window.width + red.width * 0.6
    $red.y = $window.height - red.height * 0.45
    $blue.x = ($window.width - blue.width * 0.8) / 2
    $blue.y = -blue.height * 0.635 + $window.height * 0.17
  }
</script>

{#if alive}
  <div
    class=" w-full over flex flex-row justify-center flex-wrap relative scrollbar-window-padding">
    <div class=" mt-xlg relative " transition:fly={{ y: -1000, duration: 300 }}>
      <div
        class="auto-rows-layout  max-w-layout  grid-cols-layout relative grid gap-x-md gap-y-sm mx-auto">
        <div class="col-start-1 row-span-1 row-start-1 col-span-1 m-auto">
          <Link bind:alive href="../">
            <Logo white={true} />
          </Link>
        </div>
        <div
          class="col-start-4 row-span-1 row-start-1 col-span-1 m-auto w-full h-full">
          <Buton white={true} disable={true} bind:alive link="../"
            >Plagiat</Buton>
        </div>
        <div
          class="col-start-5 col-span-1 row-span-1 row-start-1 m-auto w-full h-full">
          <Buton white={true} disable={true} bind:alive link="../"
            >Profesori</Buton>
        </div>
        <div
          class="col-start-6 row-span-1 row-start-1 col-span-1 m-auto w-full h-full">
          <LoginButton white={true} />
        </div>
        <div
          class=" grid  col-start-6 col-span-1 row-span-1 row-start-2 mx-auto">
          <UploadButton bind:alive link={'../upload'} />
        </div>

        <div class="col-start-1 row-span-1 row-start-3 col-end-4 my-auto ">
          <Search {page_name} isBig={true} isAtHome={false} bind:alive />
        </div>
        <button
          class="bg-white bg-opacity-0 row-span-1 row-start-3  text-white focus:outline-none outline-none  col-start-4 col-span-1 text-sm"
          class:underline={eseuri_chosen}
          on:click={show_eseuri}>Eseuri</button>
        <button
          class="bg-white bg-opacity-0 text-white row-span-1 row-start-3  focus:outline-none  col-start-5 col-span-1 text-sm"
          class:underline={!eseuri_chosen}
          on:click={show_caracterizari}>Caracterizari</button>

        {#if eseuri_chosen == true}
          <div
            class="grid-cols-essays auto-rows-essays max-w-layout grid relative fixed grid row-start-4  col-start-1 col-end-7 overflow-x-visible w-full h-full gap-x-lg gap-y-sm "
            transition:fly={{ x: -100, duration: 100 }}>
            {#each eseuri as { name, scriitor }}
              <div rel="preload" class="h-full w-full">
                <Essay bind:alive {name} {scriitor} works={0} white={true} />
              </div>
            {/each}
          </div>
        {:else}
          <div
            class="grid-cols-essays auto-rows-essays max-w-layout grid relative fixed grid row-start-4  col-start-1 col-end-7 overflow-x-visible w-full h-full gap-x-lg gap-y-sm "
            transition:fly={{ x: 100, duration: 100 }}>
            {#each caracterizari as { name, scriitor }}
              <Essay bind:alive {name} {scriitor} works={0} white={true} />
            {/each}
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}
