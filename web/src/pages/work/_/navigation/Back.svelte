<script lang="ts">
  import Base from './internal/Base.svelte'
  import icon from 'svelte-material-icons/ChevronLeft.svelte'

  export let disabled: boolean
</script>

<Base {icon} {disabled} on:click />
