<script lang="ts">
  import Link from '$/components/Link.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { fly } from 'svelte/transition'
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
    class="w-full flex flex-row justify-center flex-wrap relative scrollbar-window-padding"
    transition:fly={{ y: -$window.height, duration: 300 }}>
    <div class="parent relative mt-xlg ">
      <div
        class="container relative grid gap-x-l_gap_column gap-y-l_gap_row  mx-md  ">
        <div class="row-start-4  col-start-4 col-end-6">
          <Link href="../" bind:alive>
            <div class="text-xl top-auto font-serif font-bold ">
              Eseuri<span class="text-orange">.</span>
            </div>
          </Link>
        </div>
        <div
          class="blur  row-start-2 row-end-8 col-start-1 col-end-3 border-black border white_thing relative bg-white bg-opacity-50 " />
        <div
          class="row-start-2 row-end-3 col-start-1 col-end-3 mx-auto my-auto relative">
          Publică o lucrare
        </div>

        <div
          class=" flex row-start-3 row-end-4 col-start-1 frame col-end-3 border border-black z-10 ">
          <div class="mx-sm my-auto bold  w-1/2 relative">Scrie-o aici</div>
          <div class="flex w-1/2 my-auto justify-end">
            <svg
              width="16"
              height="14"
              viewBox="0 0 16 14"
              fill="none"
              class="mr-sm"
              xmlns="http://www.w3.org/2000/svg">
              <path
                d="M10 12H0V14H10V12ZM16 4H0V6H16V4ZM0 10H16V8H0V10ZM0 0V2H16V0H0Z"
                fill="black" />
            </svg>
          </div>
        </div>
        <div class="row-start-4 row-end-5 col-start-1 col-end-3  ">
          <Link bind:alive href="../upload_configure">
            <div class="flex w-full h-full frame bg-blue relative">
              <div class="ml-sm my-auto bold w-auto text-white  ">
                Încarcă un document
              </div>
              <div class="flex w-1/2 my-auto justify-end">
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 20 20"
                  fill="none"
                  class="mr-sm"
                  xmlns="http://www.w3.org/2000/svg">
                  <path
                    d="M2 4H0V18C0 19.1 0.9 20 2 20H16V18H2V4ZM18 0H6C4.9 0 4 0.9 4 2V14C4 15.1 4.9 16 6 16H18C19.1 16 20 15.1 20 14V2C20 0.9 19.1 0 18 0ZM17 9H7V7H17V9ZM13 13H7V11H13V13ZM17 5H7V3H17V5Z"
                    fill="#FCFAF9" />
                </svg>
              </div>
            </div>
          </Link>
        </div>
        <div
          class="flex  row-start-5 row-end-6 col-start-1 frame col-end-3 text-white frame_google  relative">
          <div class="ml-sm my-auto bold w-auto  ">Încarcă din Google Docs</div>
          <div class="flex w-1/2 my-auto justify-end">
            <svg
              width="16"
              height="20"
              viewBox="0 0 16 20"
              fill="none"
              class="mr-sm"
              xmlns="http://www.w3.org/2000/svg">
              <path
                d="M10 0H2C0.9 0 0.0100002 0.9 0.0100002 2L0 18C0 19.1 0.89 20 1.99 20H14C15.1 20 16 19.1 16 18V6L10 0ZM12 16H4V14H12V16ZM12 12H4V10H12V12ZM9 7V1.5L14.5 7H9Z"
                fill="#FCFAF9" />
            </svg>
          </div>
        </div>
        <div
          class="row-start-6 row-end-7 col-start-1 frame col-end-3  relative mx-auto my-auto">
          Ai scris de mână?
        </div>
        <div
          class=" flex row-start-7 row-end-8 col-start-1 frame w-full h-full col-end-3 bg-red relative">
          <div class=" mx-sm my-auto bold text-white w-1/2 relative">
            Încarcă imagini/PDF
          </div>
          <div class="flex w-1/2 my-auto justify-end">
            <svg
              width="19"
              height="18"
              viewBox="0 0 19 18"
              fill="none"
              class="mr-sm"
              xmlns="http://www.w3.org/2000/svg">
              <path
                d="M2.58997 3.89C3.28997 3.18 3.98997 2.54 4.29997 2.67C4.79997 2.87 4.29997 3.7 3.99997 4.19C3.74997 4.61 1.13997 8.08 1.13997 10.5C1.13997 11.78 1.61997 12.84 2.47997 13.48C3.22997 14.04 4.21997 14.21 5.11997 13.94C6.18997 13.63 7.06997 12.54 8.17997 11.17C9.38997 9.68 11.01 7.73 12.26 7.73C13.89 7.73 13.91 8.74 14.02 9.52C10.24 10.16 8.63997 13.19 8.63997 14.89C8.63997 16.59 10.08 17.98 11.85 17.98C13.48 17.98 16.14 16.65 16.54 11.88H19V9.38H16.53C16.38 7.73 15.44 5.18 12.5 5.18C10.25 5.18 8.31997 7.09 7.55997 8.02C6.97997 8.75 5.49997 10.5 5.26997 10.74C5.01997 11.04 4.58997 11.58 4.15997 11.58C3.70997 11.58 3.43997 10.75 3.79997 9.66C4.14997 8.57 5.19997 6.8 5.64997 6.14C6.42997 5 6.94997 4.22 6.94997 2.86C6.94997 0.69 5.30997 0 4.43997 0C3.11997 0 1.96997 1 1.71997 1.25C1.35997 1.61 1.05997 1.91 0.839966 2.18L2.58997 3.89ZM11.88 15.55C11.57 15.55 11.14 15.29 11.14 14.83C11.14 14.23 11.87 12.63 14.01 12.07C13.71 14.76 12.58 15.55 11.88 15.55Z"
                fill="#FCFAF9" />
            </svg>
          </div>
        </div>

        <div class="row-start-6 row-span-1 col-start-4 col-end-6 ">
          Perfecționează-ți-le cu cea mai extinsă colecție din România!
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  .container {
    grid-template-columns: repeat(6, 1fr);
    grid-auto-rows: var(--l_row);
    max-width: calc(var(--l_column) * 6 + var(--l_gap_column) * 5);
  }

  .white_thing {
    position: relative;
    margin-left: calc(-1 * (var(--l_gap_column)));
    margin-top: calc(-1 * (var(--l_gap_row)));
    border-radius: 20px;
    width: calc((var(--l_gap_column) * 3) + (var(--l_column) * 2));
    height: calc((var(--l_gap_row) * 7) + (var(--l_row) * 6));
  }
  .frame {
    border-radius: 20px;
  }
  .frame_google {
    background-color: #337dfa;
  }
</style>
