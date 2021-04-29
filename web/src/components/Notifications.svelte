<script context="module" lang="ts">
  import { notifications } from '@tmaxmax/renderless-svelte/src/Notifications.svelte'
  import type { Payload } from './Notification.svelte'

  export function notify(...payload: Payload[]) {
    payload.forEach(p => notifications.push(p))
  }

  export function unnotify(count = 1) {
    while (count--) {
      notifications.pop()
    }
  }

  export type { Payload as Notification }
</script>

<script>
  import Notifications from '@tmaxmax/renderless-svelte/src/Notifications.svelte'
  import Notification from './Notification.svelte'

  /**
   * The duration the notifications will be kept on-screen, in milliseconds.
   */
  export let duration = 5000
</script>

<Notifications let:payload {duration}>
  <Notification {...payload} />
</Notifications>
