<script>
  import Base from './Base.svelte'
  import { border, background, innerShadow } from '$/lib'
</script>

<Base let:theme>
  <div
    class="grid gap-x-md gap-y-sm px-md py-sm grid-cols-form auto-rows-layout rounded {background[
      theme
    ]} {border.color[theme]} {border.all[theme]} {innerShadow[theme]}">
    <slot {theme} />
  </div>
</Base>
