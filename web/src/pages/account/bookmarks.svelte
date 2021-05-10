<script lang="ts">
  import { Table, Row, Header } from './_/table'
  import Bookmarks from './_/Bookmarks.svelte'
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
