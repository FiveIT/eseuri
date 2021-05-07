<script lang="ts">
  import { onMount } from 'svelte'
  import Link from './nav/buttons/internal/Link.svelte'
  import { LayoutContext } from '.'
  import { text, border, filterShadow } from '$/lib'
  import type { UnrevisedWork } from '$/lib'

  let titleParent: HTMLElement
  let titleChild: HTMLElement
  let creatorParent: HTMLElement
  let creatorChild: HTMLElement

  function fixFontSize(parent: HTMLElement, child: HTMLElement, compensation = 1) {
    const { height: parentHeight } = parent.getBoundingClientRect()
    const { height: childHeight } = child.getBoundingClientRect()

    if (childHeight > parentHeight) {
      const p = parentHeight / childHeight
      const fontSize = parseInt(window.getComputedStyle(child).fontSize)
      child.style.fontSize = `${p * compensation * fontSize}px`
    }
  }

  onMount(() => {
    fixFontSize(titleParent, titleChild, 1.15)
    fixFontSize(creatorParent, creatorChild)
  })

  export let work: UnrevisedWork
  let titleof: string
  let message: string
  let nameauthor: string
  let str1: string = 'Eseu de '
  let str2: string = 'Caracterizare de '
  if (work.essay != null) {
    nameauthor =
      work.essay.title.author.first_name +
      ' ' +
      work.essay.title.author.middle_name +
      ' ' +
      work.essay.title.author.last_name
    ;(message = str1 + work.users_all.first_name + ' '),
      work.users_all.middle_name + ' ' + work.users_all.last_name
    titleof = work.essay.title.name
  } else {
    nameauthor = work.characterization.character.title.name
    ;(message = str2 + work.users_all.first_name + ' '),
      work.users_all.middle_name + ' ' + work.users_all.last_name
    titleof = work.characterization.character.name
  }
</script>

<LayoutContext let:theme>
  <Link href={`/essays/${titleof}`}>
    <dl
      class="grid w-full grid-flow-row h-full grid-rows-4 gap-y-xs px-sm py-xs font-sans antialiased rounded leading-none {text[
        theme
      ]} {border.color[theme]} {border.size[theme]} {filterShadow[theme]}"
      class:white-bg={theme === 'default'}
      class:blur={theme === 'default'}>
      <dt class="row-span-2 h-full flex flex-col" bind:this={titleParent}>
        <h2 class="text-md mt-auto" bind:this={titleChild}>
          {titleof}
        </h2>
      </dt>
      <dt class="self-center h-full flex flex-col" bind:this={creatorParent}>
        <span class="text-workInfo my-auto" bind:this={creatorChild}>{nameauthor}</span>
      </dt>
      <dt class="text-workInfo">
        {message}
      </dt>
    </dl>
  </Link>
</LayoutContext>
