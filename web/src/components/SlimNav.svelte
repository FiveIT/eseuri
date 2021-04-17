<script>
  import Logo from './Logo.svelte'
  import NavButton from './NavButton.svelte'
  import LoginButton from './LoginButton.svelte'
  import UploadButton from './UploadButton.svelte'
</script>

<nav class="w-full grid grid-cols-layout auto-rows-layout gap-y-sm">
  <div class="flex space-x-md w-full grid-span-6">
    <Logo />
    <div class="justify-self-end grid grid-flow-row gap-x-md auto-cols-layout">
      <NavButton href="/search" hideIfDisabled={true}>Cauta</NavButton>
      <NavButton enable={false}>Plagiat</NavButton>
      <NavButton enable={false}>Profesori</NavButton>
      <LoginButton />
    </div>
  </div>
  <div class="col-start-6 col-span-1">
    <UploadButton />
  </div>
</nav>
