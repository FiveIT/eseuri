import { px, clamp } from '$/lib'

export { default as BaseLayout } from './Layout.svelte'
export { default as Base } from './Base.svelte'

interface FitTextProperties {
  /**
   * The deduced font size is multiplied with this value
   * in order to produce a more pleasing resizing. Set this
   * to your own taste.
   *
   * The default value does not modify the final font size.
   *
   * @default 1
   */
  compensation: number
  /**
   * The lower bound to limit the possible resizing values to.
   *
   * @default 1rem
   */
  min: number
  /**
   * The upper bound to limit the possible resizing values to.
   *
   * @default 1.75rem
   */
  max: number
}

const defaultFontSizeProps: FitTextProperties = {
  compensation: 1,
  min: parseInt(px(1)),
  max: parseInt(px(1.75)), // text-md
}

const observed: Map<Element, FitTextProperties> = new Map()

const observer = new IntersectionObserver(
  entries => {
    entries
      .map(entry => {
        if (!entry.isIntersecting) {
          return
        }

        const { compensation, min, max } = observed.get(entry.target)!

        const child = entry.target.children[0] as HTMLElement

        const { height: ph } = entry.boundingClientRect
        const { height: ch } = child.getBoundingClientRect()

        destroy(entry.target)

        if (ch <= ph) {
          return
        }

        const p = ph / ch
        const fontSize = parseInt(window.getComputedStyle(child).fontSize)

        return `${clamp(p * fontSize * compensation, min, max)}px`
      })
      .forEach((fontSize, i) => {
        if (fontSize) {
          const elem = entries[i].target.children[0] as HTMLElement

          elem.style.fontSize = fontSize
        }
      })
  },
  { threshold: 1 }
)

function destroy(target: Element) {
  observer.unobserve(target)
  observed.delete(target)
}

/**
 * Lazily resizes the font of the first child of the element the action is applied to
 * when it becomes visible in the viewport.
 *
 * For this to work, the text must overflow vertically. To achieve this behaviour
 * for text without blanks, add the CSS property `overflow-wrap: break-words`.
 */
export function fitText(node: Element, props?: Partial<FitTextProperties>) {
  const preferences = {
    ...defaultFontSizeProps,
    ...props,
  }

  if (node.children.length === 0) {
    return { update() {}, destroy() {} }
  }

  observed.set(node, preferences)
  observer.observe(node)

  return {
    update() {},
    destroy() {
      destroy(node)
    },
  }
}
