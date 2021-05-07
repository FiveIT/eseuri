import { px, clamp } from '$/lib'

interface AdjustFontSizeProperties {
  compensation: number
  min: number
  max: number
}

const defaultFontSizeProps: AdjustFontSizeProperties = {
  compensation: 1,
  min: parseInt(px(1)),
  max: parseInt(px(1.75)), // text-md
}

export function fitText(node: HTMLElement, props?: Partial<AdjustFontSizeProperties>) {
  const { compensation, min, max } = {
    ...defaultFontSizeProps,
    ...props,
  }

  if (node.children.length === 0) {
    return { update() {}, destroy() {} }
  }

  const child = node.children[0] as HTMLElement

  const childHeight = child.getBoundingClientRect().height
  const parentHeight = node.getBoundingClientRect().height

  if (childHeight > parentHeight) {
    const p = parentHeight / childHeight
    const fontSize = parseInt(window.getComputedStyle(child).fontSize)
    child.style.fontSize = `${clamp(p * fontSize * compensation, min, max)}px`
  }

  return {
    update() {},
    destroy() {},
  }
}
