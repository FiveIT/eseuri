<script>
  import LoginButton from '$/components/LoginButton.svelte'
  import Logo from '$/components/Logo.svelte'
  import Button from '$/components/NavButton.svelte'
  import Search from '$/components/SearchBar.svelte'
  import UploadButton from '$/components/UploadButton.svelte'
</script>

<Logo />
<div class="col-start-3 col-end-6 my-auto">
  <Search />
</div>
<div class="col-start-6">
  <LoginButton theme="white" />
</div>
<div class="col-start-4 my-auto">
  <Button disable theme="white">Plagiat</Button>
</div>
<div class="col-start-5 my-auto">
  <Button disable theme="white">Profesori</Button>
</div>
<div class="col-start-6 row-start-3 place-self-center">
  <UploadButton />
</div>
