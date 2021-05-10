import { px, clamp } from '$/lib'

export { default as BaseLayout } from './Layout.svelte'
export { default as Base } from './Base.svelte'

interface FitTextProperties {
  compensation: number
  min: number
  max: number
}

const defaultFontSizeProps: FitTextProperties = {
  compensation: 1,
  min: parseInt(px(1)),
  max: parseInt(px(1.75)), // text-md
}

const noop = {
  update() {},
  destroy() {},
} as const

const observed: Map<Element, FitTextProperties & { done: boolean }> = new Map()

const observer = new IntersectionObserver(
  entries => {
    entries
      .map(entry => {
        const { compensation, min, max, done } = observed.get(entry.target)!

        if (done) {
          return
        }

        const child = entry.target.children[0] as HTMLElement

        const parentHeight = entry.boundingClientRect.height
        const childHeight = child.getBoundingClientRect().height

        if (childHeight <= parentHeight) {
          return
        }

        const p = parentHeight / childHeight
        const fontSize = parseInt(window.getComputedStyle(child).fontSize)

        return [child, `${clamp(p * fontSize * compensation, min, max)}`] as const
      })
      .forEach(change => {
        if (!change) {
          return
        }

        change[0].style.fontSize = change[1]
      })
  },
  {
    root: document.querySelector('#app'),
    rootMargin: '0px',
    threshold: 1.0,
  }
)

export function fitText(node: Element, props?: Partial<FitTextProperties>) {
  const { compensation, min, max } = {
    ...defaultFontSizeProps,
    ...props,
  }

  if (node.children.length === 0) {
    return noop
  }

  const child = node.children[0] as HTMLElement

  const childHeight = child.getBoundingClientRect().height
  const parentHeight = node.getBoundingClientRect().height

  if (childHeight > parentHeight) {
    const p = parentHeight / childHeight
    const fontSize = parseInt(window.getComputedStyle(child).fontSize)
    child.style.fontSize = `${clamp(p * fontSize * compensation, min, max)}px`
  }

  return noop
}
