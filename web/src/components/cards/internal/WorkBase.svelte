<script lang="ts">
  import Base from './Base.svelte'
  import { Link } from '$/components'

  export let href: string
  export let heading: string
  export let middle: string
  export let end: string

  export let onBeforeNavigate: () => Promise<boolean | undefined> | boolean | undefined = () => true
</script>

<Link {href} {onBeforeNavigate}>
  <Base>
    <div slot="heading" class="text-md mt-auto">{heading}</div>
    <div slot="middle" class="text-workInfo leading-none my-auto">{middle}</div>
    <div slot="end" class="text-workInfo">{end}</div>
  </Base>
</Link>
