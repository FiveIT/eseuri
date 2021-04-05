<script lang="ts">
  import Carousel from '@tmaxmax/renderless-svelte/src/Carousel.svelte'
  import type { CarouselControls } from '@tmaxmax/renderless-svelte/src/Carousel.svelte'
  import Queue from '$/queue'
  import NewFactButton from './_components/NewFactButton.svelte'
  import FactNavButton from './_components/FactNavButton.svelte'
  import Text from '$/components/text/Inline.svelte'
  import TextProse from '$/components/text/prose/Inline.svelte'
  import { metatags, ready } from '@roxi/routify'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { onMount } from 'svelte'

  metatags.title = 'Cat facts'

  const responses: Promise<string[]>[] = []
  let response: string[] | undefined

  const getFact = async () => {
    const length = response?.length ?? 0
    if (length < 5) {
      if (responses.length < 2) {
        const res = fetch(
          'https://cat-fact.herokuapp.com/facts/random?amount=10'
        )
          .then(res => res.json() as Promise<{ text: string }[]>)
          .then(res => res.map(r => r.text))
        responses.push(res)
      }
      if (length === 0) {
        response = await responses.shift()!
      }
    }
    return response!.shift()!
  }

  let history = new Queue<Promise<string>>(10)
  let items: any[]

  const pushHistory = () => {
    const fact = getFact()
    history.push(fact)
    items = history.array() as any[]
    return fact
  }

  pushHistory().then($ready)

  type Handler = () => void

  let controls: CarouselControls

  const keydownHandler = (left: Handler, right: Handler) => (
    ev: KeyboardEvent
  ) => {
    switch (ev.code) {
      case 'KeyH':
      case 'ArrowLeft':
        left()
        break
      case 'KeyL':
      case 'ArrowRight':
        right()
        break
    }
  }

  let mounted = false

  onMount(() => {
    $orange = {
      x: 0,
      y: $window.height - orange.height,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
    }
    $red = {
      x: $window.width - red.width * 1.5,
      y: $window.height - red.height * 0.45,
      scale: 1.2,
      rotate: 32.5,
      flip: {
        x: 1,
        y: 0,
      },
    }
    $blue = {
      x: ($window.width - blue.width * 0.49) / 2,
      y: -blue.height * 0.635 + $window.height * 0.1,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 1,
      },
    }
    mounted = true
  })

  $: if (mounted) {
    $orange.y = $window.height - orange.height
    $red.x = $window.width - red.width * 1.5
    $red.y = $window.height - red.height * 0.45
    $blue.x = ($window.width - blue.width * 0.49) / 2
    $blue.y = -blue.height * 0.635 + $window.height * 0.1
  }
</script>

<Carousel {items} let:payload bind:controls let:currentIndex let:setIndex>
  <div class="flex flex-col items-center space-y-sm w-full min-h-full">
    {#await payload}
      <p class="text-center max-w-prose text-blue">
        <Text>Retrieving a cat fact...</Text>
      </p>
    {:then text}
      <p class="text-center max-w-prose">
        <TextProse>{text}</TextProse>
      </p>
    {:catch}
      <p class="text-center max-w-prose text-red">
        <Text>Something terribly bad happened!</Text>
      </p>
    {/await}
  </div>
  <div class="flex space-x-sm items-center mt-auto mb-sm">
    <FactNavButton on:click={controls.previous} disabled={currentIndex === 0}>
      Previous
    </FactNavButton>
    <FactNavButton
      on:click={controls.next}
      disabled={!items || currentIndex === items.length - 1}>
      Next
    </FactNavButton>
  </div>
  <NewFactButton on:click={() => (pushHistory(), setIndex(history.length - 1))}>
    New fact
  </NewFactButton>
</Carousel>

<svelte:window on:keydown={keydownHandler(controls.previous, controls.next)} />
