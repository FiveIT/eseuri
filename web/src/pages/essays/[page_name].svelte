<script context="module" lang="ts">
  import type { Readable } from 'svelte/store'
  import { writable } from 'svelte/store'

  /**
   * The key used to retrieve the context from children components.
   */
  export const contextKey = {}

  interface Store {
    /**
     * True if the work is bookmarked.
     */
    readonly saved: boolean
    /**
     * The name of the opened work.
     */
    readonly work: string
  }
  export interface Context extends Readable<Store> {
    /**
     * Bookmarks the work, if not already.
     */
    save(): void
    /**
     * Removes the work from bookmarks, if bookmarked before.
     */
    unsave(): void
  }

  /**
   * Creates a context for the current work.
   *
   * @param work The name of the opened work.
   */
  function createContext(work: string): Context {
    /**
     * True if the work is bookmarked.
     */
    let saved = false
    const { subscribe, update } = writable<Store>({
      // Getters are used so the values cannot be modified from outside.
      get saved() {
        return saved
      },
      get work() {
        return decodeURI(work)
      },
    })

    // Normally, some fetch requests to the API would exist
    // here, instead of a boolean flag.
    return {
      subscribe,
      save() {
        // Update is called so the store notifies the change to
        // the subscribers, even though no actual value in the
        // store itself changes.
        update(v => {
          saved = true
          return v
        })
      },
      unsave() {
        update(v => {
          saved = false
          return v
        })
      },
    }
  }
</script>

<script lang="ts">
  import SlimNav from '$/components/SlimNav.svelte'
  import FavButton from '$/components/BookmarkButton.svelte'
  import Next from 'svelte-material-icons/ChevronRight.svelte'
  import Back from 'svelte-material-icons/ChevronLeft.svelte'
  import Layout from '$/components/Layout.svelte'
  import { store as orange } from '$/components/blob/Orange.svelte'
  import { store as red } from '$/components/blob/Red.svelte'
  import { store as blue } from '$/components/blob/Blue.svelte'
  import { store as window } from '$/components/Window.svelte'
  import { setContext } from 'svelte'

  import type { BlobPropsInput } from '$/types'

  export let page_name: string

  // Create the current work's context
  setContext<Context>(contextKey, createContext(page_name))

  let orangeBlobProps: BlobPropsInput = { scale: 1.8 }
  $: orangeBlobProps = {
    x: -orange.width * 1.4,
    y: $window.height - orange.height,
  }

  let redBlobProps: BlobPropsInput = {
    scale: 2,
    rotate: 180 + 26.7,
  }
  $: redBlobProps = {
    x: $window.width + red.width * 0.6,
    y: $window.height - red.height * 0.45,
  }

  let blueBlobProps: BlobPropsInput = { scale: 1.4 }
  $: blueBlobProps = {
    x: ($window.width - blue.width * 1) / 2,
    y: -blue.height * 1 - $window.height * 0.1,
    scale: 1.4,
  }
</script>

<Layout {orangeBlobProps} {redBlobProps} {blueBlobProps}>
  <SlimNav />
  <div class="col-start-1 col-span-1 row-start-3 row-span-1">
    <button class="fixed mt-40">
      <Back size="4rem" color="var(--light-gray)" />
    </button>
  </div>
  <div class="col-start-6 col-span-1 row-start-3 row-span-1 ">
    <button class="fixed mt-40">
      <Next size="4rem" color="var(--light-gray)" />
    </button>
  </div>
  <div class="col-start-2 col-end-6 row-start-3 flex flex-col justify-between">
    <h2 class="text-title font-serif mt-sm antialiased">
      {decodeURI(page_name)}
    </h2>
    <div class="flex-row flex w-full justify-between align-middle mt-sm">
      <div class="relative w-min mt-sm text-sm font-sans antialiased">Eseu</div>
      <div class="relative w-min mt-sm"><FavButton /></div>
    </div>
    <div>
      <p class="text-prose font-serif mt-sm antialiased">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec est nibh,
        tristique non magna maximus, maximus ornare nibh. Ut cursus libero in mi
        egestas blandit. Quisque tincidunt enim nec ex dignissim mattis eget ac
        nisi. Suspendisse consectetur molestie leo, iaculis dictum erat vehicula
        vitae. Fusce aliquet lorem suscipit, convallis ante at, ultricies augue.
        Proin aliquam, ligula at finibus dignissim, erat nisi rhoncus justo, at
        posuere velit lorem vitae augue. Ut ultrices nulla tincidunt tristique
        convallis. Nunc magna est, vestibulum eu ante sed, sagittis auctor
        mauris. Vivamus sit amet dignissim mauris, at porta orci. Etiam commodo
        vel eros porttitor interdum. Nullam dolor dui, dapibus quis felis nec,
        tempor vehicula ligula. Mauris tortor orci, eleifend vel urna a,
        fringilla rutrum lorem. Nulla laoreet, leo ut vestibulum interdum, felis
        nisi consequat dolor, in congue justo sapien et augue. Ut malesuada
        rutrum nunc eu eleifend. Donec bibendum nunc sed mauris eleifend
        tristique. Etiam ullamcorper ac turpis et blandit. Suspendisse varius
        magna id consequat sodales. Pellentesque habitant morbi tristique
        senectus et netus et malesuada fames ac turpis egestas. Vivamus
        pellentesque odio nisl, facilisis consectetur quam ornare eu. Cras
        porttitor, arcu nec dictum posuere, orci odio varius mi, eget bibendum
        nibh nisl ut mauris. Quisque placerat nulla arcu, commodo varius ipsum
        ultrices vel. Integer a velit scelerisque, dictum arcu eu, sollicitudin
        ipsum. Quisque malesuada ultrices felis, mollis bibendum tellus
        tincidunt vel. Integer nec ex tortor. Interdum et malesuada fames ac
        ante ipsum primis in faucibus. Cras fringilla, sapien in molestie
        ullamcorper, elit mi venenatis quam, egestas porttitor turpis magna sed
        dui. Donec id bibendum orci, accumsan viverra lacus. Phasellus et
        porttitor neque, at sodales massa. Etiam sed nulla ipsum. Cras vitae
        consequat odio, eu varius orci. Suspendisse vehicula neque quis dapibus
        maximus. Aliquam in mauris sed velit ornare elementum id id justo.
        Vivamus bibendum placerat enim at sollicitudin. Donec id lorem a purus
        porttitor viverra nec non tortor. Ut dapibus felis et ante aliquam, a
        hendrerit nunc vulputate. Aliquam placerat eu magna at gravida. Vivamus
        imperdiet lorem mollis, tincidunt orci at, rhoncus risus. Suspendisse
        eleifend porta justo a faucibus. Proin mollis nunc sed eros lobortis
        consectetur. Quisque laoreet, eros a rhoncus pellentesque, felis lectus
        feugiat nunc, in lacinia erat felis sed velit. Phasellus auctor neque
        nec magna tincidunt, sit amet tincidunt nunc placerat. Nunc in iaculis
        ex. Nullam vel facilisis metus, in facilisis tortor. Vivamus et quam
        aliquet, ornare tellus vel, hendrerit lectus. Nam convallis a enim eget
        vulputate. Nam quis aliquam purus, quis faucibus est. Nunc id
        sollicitudin mauris, nec accumsan ligula. Fusce sit amet lobortis massa,
        at ultricies urna. Praesent mattis vehicula justo, a blandit tellus
        dapibus non. Sed vitae pellentesque dolor. Aliquam erat volutpat.
        Aliquam a mollis quam, sit amet malesuada orci. Curabitur ac urna in
        mauris pulvinar vestibulum et in sem. Nunc laoreet nisl at erat iaculis
        laoreet. Praesent molestie nisi eros, quis mattis dui pulvinar sed.
        Donec tincidunt vitae libero vel fringilla. Aliquam ut leo at diam
        fringilla rhoncus sed non neque. Phasellus et urna odio. Vivamus nibh
        felis, sodales quis euismod at, varius elementum mi. Nullam pretium
        neque non eleifend
      </p>
    </div>
    <div class="mt-sm">
      <FavButton />
    </div>
  </div>
</Layout>
