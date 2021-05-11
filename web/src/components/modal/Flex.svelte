<script>
  import Base from './Base.svelte'
  import { border, background, innerShadow } from '$/lib'
</script>

<Base let:theme>
  <div
    class="flex flex-col w-delete-box items-center space-y-md px-md pt-md pb-sm rounded {background[
      theme
    ]} {border.color[theme]} {border.all[theme]} {innerShadow[theme]}">
    <slot {theme} />
  </div>
</Base>
