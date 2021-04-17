<script lang="ts">
  import Link from './Link.svelte'
  import LayoutContext from './LayoutContext.svelte'
  import AutoSize from './text/AutoSize.svelte'

  import windi from '../../windi.config'
  const fontSize = windi.theme!.fontSize as Record<string, [string]>

  import type { Work } from '$/types'

  import { text, border } from '$/theme'
  import { workTypeTranslation } from '$/content'

  export let work: Work

  let nameHeight: number, creatorHeight: number
  const min = parseInt(fontSize['sm'][0])
  const max = parseInt(fontSize['md'][0])
  const unit = 0.01
</script>

<LayoutContext let:theme>
  <Link href={`/essays/${work.name}`}>
    <dl
      class="grid w-full h-full grid-cols-4 gap-x-xs p-sm font-sans subpixel-antialiased {text[
        theme
      ]} {border.color[theme]} {border.size[theme]}">
      <dt class="grid-cols-2">
        <AutoSize {min} {max} {unit} let:fontSize textHeight={nameHeight}>
          <h2 bind:offsetHeight={nameHeight} style="font-size: {fontSize}rem;">
            {work.name}
          </h2>
        </AutoSize>
      </dt>
      <dt>
        <AutoSize
          min={min / 2}
          max={min}
          {unit}
          let:fontSize
          textHeight={creatorHeight}>
          <span
            bind:offsetHeight={creatorHeight}
            style="font-size: {fontSize}rem;">
            {work.creator}
          </span>
        </AutoSize>
      </dt>
      <dt>
        {work.work_count}{work.work_count > 19 ? ' de' : ''}
        {workTypeTranslation.ro[work.type].inarticulate[
          work.work_count === 1 ? 'singular' : 'plural'
        ]}
      </dt>
    </dl>
  </Link>
</LayoutContext>
