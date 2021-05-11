<script context="module" lang="ts">
  function getValues(hasNoTeacher: boolean, count: number) {
    const bg = count === 0 && 'gray-dark'

    if (hasNoTeacher) {
      return {
        label: 'așteaptă o revizuire',
        bg: bg || 'orange',
        title: 'Selectează lucrările care caută o revizuire',
      } as const
    }

    return {
      label: 'așteaptă revizuirea ta',
      bg: bg || 'red',
      title: 'Selectează lucrările care caută revizuirea ta',
    } as const
  }
</script>

<script lang="ts">
  export let count: [number, number] | undefined
  export let hasNoTeacher = false

  const values = [false, true] as const
</script>

{#if typeof count !== 'undefined'}
  {#each values as v, i}
    <div class="col-start-{1 + 3 * +v} col-span-3 row-start-4">
      <button
        title={getValues(v, count[i]).title}
        on:click={() => (hasNoTeacher = v)}
        class="w-full h-full flex flex-row space-x-sm items-center font-sans text-sm antialiased">
        <span
          class="w-2em h-2em rounded-full bg-{getValues(v, count[i])
            .bg} flex items-center justify-center text-white">
          {count[i]}
        </span>
        <span class:underline={hasNoTeacher === v}>
          {count[i] === 1 ? 'lucrare' : 'lucrări'}
          {getValues(v, count[i]).label}
        </span>
      </button>
    </div>
  {/each}
{/if}
