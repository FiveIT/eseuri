<script>
  import Logo from '$/components/Logo.svelte'
  import { Forgery, Teachers, Upload, Login } from '$/components/buttons'
  import Search from '$/components/SearchBar.svelte'
</script>

<Logo />
<div class="col-start-3 col-end-6 my-auto">
  <Search />
</div>
<div class="col-start-6 h-full">
  <Login theme="white" />
</div>
<div class="col-start-4 my-auto h-full">
  <Forgery theme="white" />
</div>
<div class="col-start-5 my-auto h-full">
  <Teachers theme="white" />
</div>
<div class="col-start-6 row-start-3 place-self-center h-full">
  <Upload />
</div>
