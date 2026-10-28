// Quartz plugin: Scroll Guard
//
// Excalidraw embeds bind a `wheel` listener on the drawing container that calls
// preventDefault() and zooms the drawing. That traps the page: a reader cannot
// scroll past the figure, and the drawing zooms at the same time.
//
// This plugin adds a capture-phase listener on the document. Because capture
// runs from the root downwards, it sees the wheel event before the drawing
// container does and stops it from propagating, so the embed's zoom handler
// never runs and the browser performs its normal page scroll. Nothing calls
// preventDefault(), so the page keeps scrolling. Panning and the zoom buttons
// inside the drawing are unaffected.
//
// The guard is installed once per page load and covers drawings that arrive
// later through a client-side navigation.

const SCROLLABLE_EMBEDS = [".excalidraw-container"]

const guardScript = `(function () {
  if (window.__quartzScrollGuardInstalled) return
  window.__quartzScrollGuardInstalled = true

  var SELECTOR = ${JSON.stringify(SCROLLABLE_EMBEDS.join(", "))}

  function insideEmbed(node) {
    while (node && node.nodeType === 1) {
      if (node.matches && node.matches(SELECTOR)) return true
      node = node.parentElement
    }
    return false
  }

  function guard(ev) {
    var target = ev.target
    if (target && target.nodeType !== 1) target = target.parentElement
    if (insideEmbed(target)) {
      // Stop the embed's own handler from firing; do not cancel the event, so
      // the browser still scrolls the page.
      ev.stopPropagation()
    }
  }

  document.addEventListener("wheel", guard, { capture: true, passive: true })
  document.addEventListener("touchmove", guard, { capture: true, passive: true })
})()`

export const scrollGuard = () => ({
  name: "scroll-guard",
  // Quartz categorises external plugins by the hooks they expose. This plugin
  // has no build-time work, but declaring an empty transformer hook is what
  // makes the loader register it (and therefore emit its externalResources).
  htmlPlugins: () => [],
  externalResources: () => ({
    js: [
      {
        loadTime: "afterDOMReady",
        contentType: "inline",
        script: guardScript,
      },
    ],
  }),
})

export default scrollGuard
