<script>
  import Logo from './Logo.svelte'
  import NavButton from './NavButton.svelte'
  import LoginButton from './LoginButton.svelte'
  import UploadButton from './UploadButton.svelte'
</script>

<nav class="w-full col-span-6 row-span-2">
  <div class="flex w-full">
    <Logo />
    <div class="ml-auto grid grid-flow-col gap-x-md auto-cols-layout">
      <span />
      <NavButton href="/search" hideIfDisabled={true}>Caută</NavButton>
      <NavButton enable={false}>Plagiat</NavButton>
      <NavButton enable={false}>Profesori</NavButton>
      <LoginButton />
    </div>
  </div>
  <div class="ml-auto w-min mr-md">
    <UploadButton />
  </div>
</nav>
