<script>
  import { Forgery, Teachers, Upload, Login, Logo } from './buttons'
  import { SearchBar } from '$/components'
</script>

<Logo />
<div class="col-start-3 col-end-6 my-auto">
  <SearchBar />
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
