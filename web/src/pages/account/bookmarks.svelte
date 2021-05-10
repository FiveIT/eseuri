<script lang="ts">
  import { Table, Row, Header } from './_/table'
  import Bookmarks from './_/Bookmarks.svelte'
  import { metatags } from '@roxi/routify'

  metatags.title = 'Marcaje - Contul meu - Eseuri'
</script>

<Table>
  <Row>
    <Header>Tip</Header>
    <Header cols={2}>Denumire marcaj</Header>
    <Header cols={2}>Subiect</Header>
    <Header>Timpul salvării</Header>
  </Row>
  <Bookmarks />
</Table>
