<script lang="ts">
  import Link from '$/components/link.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { fly } from 'svelte/transition'
  import ScrieAici from 'svelte-material-icons/TextSubject.svelte'
  import Docs from 'svelte-material-icons/FileDocumentBoxMultiple.svelte'
  import GoogleDocs from 'svelte-material-icons/FileDocumentOutline.svelte'
  import Doodle from 'svelte-material-icons/Gesture.svelte'
  import { onMount } from 'svelte'
  let mounted = false
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
      x: $window.width - red.width * 1,
      y: 0,
      scale: 2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
      zIndex: -1,
    }
    $blue = {
      x: $window.width * 0.65,
      y: $window.height * 0.9,
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

  export let alive = true
  $: if (mounted) {
    $orange.y = $window.height - orange.height
    $red.x = $window.width - red.width * 1
    $red.y = 0
    $blue.x = $window.width * 0.65
    $blue.y = $window.height * 0.9
  }
</script>

{#if alive}
  <div
    class="w-full flex flex-row  justify-center items-center relative scrollbar-window-padding my-auto"
    transition:fly={{ y: -$window.height, duration: 300 }}>
    <div class=" relative ">
      <div
        class="auto-rows-layout  max-w-layout  grid-cols-layout relative w-full grid gap-x-md gap-y-sm mx-auto">
        <div class="row-start-3 row-span-1  col-start-4 col-end-6">
          <Link href="../" bind:alive>
            <div class=" text-xl   font-serif font-bold ">
              <div class="h-min">
                Eseuri<span class="text-orange">.</span>
              </div>
            </div>
          </Link>
        </div>
        <div
          class="blur  row-start-1 row-end-7 col-start-1 col-end-3 border-black border -mt-sm -m-md rounded  relative bg-white bg-opacity-50 " />
        <div
          class="row-start-1 row-end- col-start-1 col-end-3 mx-auto my-auto relative text-sm">
          Publică o lucrare
        </div>

        <div
          class=" flex row-start-2 row-end-3 col-start-1 rounded col-end-3 border border-black z-10 ">
          <div class="mx-sm my-auto bold  w-1/2 relative text-sm">
            Scrie-o aici
          </div>
          <div class="flex w-1/2 my-auto justify-end mr-sm">
            <ScrieAici color="black" size="1.5rem" />
          </div>
        </div>
        <div
          class="row-start-3 row-end-4 col-start-1 col-end-3 col-span-2 row-span-1">
          <Link bind:alive href="../upload_configure">
            <div class="flex w-full h-full rounded bg-blue relative ">
              <button class="flex w-full h-full rounded bg-blue relative ">
                <div class="ml-sm my-auto bold w-full text-white text-sm  ">
                  Încarcă un document
                </div>
                <div class="flex w-1/2 my-auto justify-end mr-sm">
                  <Docs color="white" size="1.5rem" />
                </div>
              </button>
            </div>
          </Link>
        </div>
        <div
          class="flex  row-start-4 row-end-5 col-start-1 rounded col-end-3 text-white  bg-google-docs  relative    ">
          <div class="ml-sm my-auto bold w-full text-sm  ">
            Încarcă din Google Docs
          </div>
          <div class="flex w-1/2 my-auto justify-end mr-sm">
            <GoogleDocs color="white" size="1.5rem" />
          </div>
        </div>
        <div
          class="row-start-5 row-end-6 col-start-1 rounded col-end-3  relative mx-auto my-auto text-sm">
          Ai scris de mână?
        </div>
        <div
          class=" flex row-start-6 row-end-7 col-start-1 rounded w-full h-full col-end-3 bg-red relative">
          <div class=" mx-sm w-full my-auto bold text-white relative text-sm">
            Încarcă imagini/PDF
          </div>
          <div class=" flex w-1/2 my-auto justify-end mr-sm">
            <Doodle color="white" size="1.5rem" />
          </div>
        </div>

        <div class="row-start-5 row-span-1 col-start-4 col-end-6 text-sm ">
          Perfecționează-ți-le cu cea mai extinsă colecție din România!
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  button:focus {
    outline: 3px solid black rounded;
  }
</style>
