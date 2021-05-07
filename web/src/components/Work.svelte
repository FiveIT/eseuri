<script lang="ts">
  import { onMount } from 'svelte'

  import Link from './nav/buttons/internal/Link.svelte'
  import { LayoutContext } from '.'

  import type { WorkSummary } from '$/lib'

  import { text, border, filterShadow, fontWeight } from '$/lib'
  import { workTypeTranslation } from '$/lib/content'

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
    fixFontSize(titleParent, titleChild, 1.1)
    fixFontSize(creatorParent, creatorChild)
  })

  export let work: WorkSummary
</script>

<LayoutContext let:theme>
  <Link href={`/work/${work.type}/${work.url}`}>
    <dl
      class="group grid w-full grid-flow-row h-full grid-rows-4 gap-y-xs px-sm py-xs font-sans antialiased rounded leading-none {text[
        theme
      ]} {border.color[theme]} {border.size[theme]} {filterShadow[theme]} {fontWeight[theme]}"
      class:white-bg={theme === 'default'}
      class:blur={theme === 'default'}>
      <dt class="row-span-2 h-full flex flex-col" bind:this={titleParent}>
        <h2 class="text-md mt-auto" bind:this={titleChild}>
          {work.name}
        </h2>
      </dt>
      <dt class="self-center h-full flex flex-col" bind:this={creatorParent}>
        <span class="text-workInfo leading-none my-auto" bind:this={creatorChild}
          >{work.creator}</span>
      </dt>
      <dt class="text-workInfo">
        {work.work_count}{work.work_count > 19 ? ' de' : ''}
        {workTypeTranslation.ro[work.type].inarticulate[
          work.work_count === 1 ? 'singular' : 'plural'
        ]}
      </dt>
    </dl>
  </Link>
</LayoutContext>
