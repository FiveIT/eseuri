<script>
  import { ready } from '@roxi/routify'
  import { onMount } from 'svelte'
  import Text from '$/components/text/Inline.svelte'
  import TextProse from '$/components/text/prose/Inline.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'

  let mounted = false

  onMount(() => {
    $orange = {
      x: 10,
      y: $window.height - orange.height - 20,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
    }
    $red = {
      x: $window.width - red.width,
      y: 0,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
    }
    $blue = {
      x: $window.width - blue.width * 1.03,
      y: $window.height - blue.height * 0.4,
      scale: 1.2,
      rotate: 0,
      flip: {
        x: 0,
        y: 0,
      },
    }
    mounted = true
  })

  $: if (mounted) {
    $orange.y = $window.height - orange.height - 20
    $red.x = $window.width - red.width
    $blue.x = $window.width - blue.width * 1.03
    $blue.y = $window.height - blue.height * 0.4
  }

  const getBeeMovieScript = () =>
    fetch(
      'https://gist.githubusercontent.com/The5heepDev/a15539b297a7862af4f12ce07fee6bb7/raw/7164813a9b8d0a3b2dcffd5b80005f1967887475/entire_bee_movie_script'
    ).then(res => res.text())

  const script = getBeeMovieScript()

  const composition = fetch(`${import.meta.env.FUNCTIONS_URL}/`).then(res =>
    res.text()
  )

  Promise.all([script, composition]).then($ready)
</script>

<div class="flex flex-col items-center">
  <p><Text>This page presents many cat facts.</Text></p>
  <p><Text>But also the Bee Movie script!</Text></p>
  {#await script then text}
    <div
      class="blur flex flex-col items-center space-y-md p-md border rounded mt-lg bg-white bg-opacity-50">
      <h2
        class="font-serif text-center text-title subpixel-antialiased text-black font-normal">
        The Bee Movie Script
      </h2>
      <p class="max-w-prose">
        <TextProse>{text}</TextProse>
      </p>
    </div>
  {:catch}
    <p class="text-red"><Text>Something terribly unholy happened!</Text></p>
  {/await}
</div>
<footer class="mt-lg flex flex-col items-center">
  {#await composition then text}
    <p class="text-green"><Text>{text}</Text></p>
  {:catch err}
    <p class="text-red"><Text>Nani the fuck?</Text></p>
    <pre class="text-red">{err}</pre>
  {/await}
</footer>
