# abla-ui

The parts of a component UI that don't depend on where it is drawn, written in
[Abla](https://github.com/AndreBaltazar8/ablac): state with change tracking, flex layout, a retained tree of components
with keyed reconciliation, input and focus over it, and a kit of controls. It is shared by
[abla-one](https://github.com/AndreBaltazar8/abla-one) (applications on Android, the web, desktop and e-paper) and
abla-forge (the game engine, not public yet), which each bring a renderer, real fonts and
their platform's input.

It imports only the Abla standard library: no renderer, no platform, no application code.
Text is measured through an interface the caller supplies (`TextFont`), so one side can use
width tables and another real fonts. Painting goes through `ViewPainter`, input comes in as
`ViewInput`.

## What is here

| Module | What it does |
|---|---|
| `src/state.ab` | `State<T>`: a value whose changes move a global revision (an app re-renders), queue the render scopes that read it (a component re-renders alone) and count its own version (a game polls one value). |
| `src/flex.ab` | Flex layout: rows, columns and stacks; gap, padding, align, justify, grow, shrink, wrap, min/max, scrolling axes, anchored absolute children. Each node caches its last layout and measurement; setters mark only real changes; a fixed-size node bounds a relayout to its own subtree. |
| `src/text.ab` | Line breaking over any font (`TextFont`): spaces, long words, newlines, max lines. |
| `src/style.ab` | Styles as ordered (condition, property, value) entries, the last match winning: interaction states (hover, pressed, focused, selected, disabled) and viewport breakpoints (`upTo`, `from`). Resolved paint (`Look`) and the theme (`Theme`). |
| `src/tree.ab` | The retained tree: elements (`El`) from components' `render()`, reconciled by key into nodes that keep their layout, look and wrapped text; per-node change records (added, removed, moved, properties); the paint walk onto a `ViewPainter`; per-frame changes without a render (`setText`, `setTranslate`, `setOpacity`, `setValue`). |
| `src/input.ab` | Input over the tree: hit testing, hover and press, sliders, focus navigation (Tab, arrows, Enter / Space, the pad), scrolling (wheel, drag), Escape closing the topmost window, tooltips. |
| `src/kit.ab` | Window, panel, button, toggle, slider, tabs, label, caption, list, list row, tooltip, built from elements and the theme. |
| `src/ui.ab` | Imports all of the above. |

## Using it

abla-ui is a package: import it from GitHub and run `ablac package update --project .` once
to resolve and lock it. One module of it is `github("AndreBaltazar8/abla-ui/flex")`.

```abla
import github("AndreBaltazar8/abla-ui")

class Settings(var open: bool by State(true), var volume: f64 by State(0.8))
val settings = Settings()

class SettingsWindow() : Component {
    fun render(): El {
        if (!settings.open) return box(style().hidden(true), [])
        windowPanel("Settings", { -> settings.open = false }, style().width(360.0).anchor(FLEX_ANCHOR_CENTER, 0.0, 0.0), [
            label("Volume", style()),
            slider(settings.volume, 0.0, 1.0, style(), { v -> settings.volume = v })
        ])
    }
}

fun makeSettings(): Component = SettingsWindow()

val tree = viewTree(myTheme, myFonts)          // myFonts: the platform's TextFont
tree.mount(comp("settings", makeSettings))
// each frame:
tree.input(events)       // ViewInput from the platform
tree.update(width, height)
tree.paint(painter)      // ViewPainter: boxes, text runs, images, clips
```

A frame where nothing changed renders no component, lays out no node, measures no text
and resolves no style: painting is one walk over cached boxes and text lines. A State
change re-renders only the components that read it; a per-frame value (an fps counter, a
name tag over a character) goes through `tree.named(...)` and `setText` / `setTranslate`
without any render.

State holds plain values (numbers, booleans, strings). Keep a collection beside a State
that counts its changes, and bump it after each edit.

## Checks

`scripts/test.sh` builds and runs every `tests/*_test.ab` natively (`ABLAC` picks the
compiler).

## Adopting it in abla-one (a proposal, not scheduled)

abla-one has its own State, Style, Node and layout (`src/core`, `src/layout`). Moving it
onto abla-ui could go in steps, each one usable on its own:

1. **State.** `core/state.ab`'s `State` and revision are the same contract as abla-ui's
   (`stateRevision()` for `oneRevision()`, `stateTouchAll()` for `oneInvalidate()`).
   Cheap: an import and two aliases.
2. **Layout for the backends that draw themselves** (desktop, epaper, web-canvas):
   `layout/layout.ab`'s measuring becomes an adapter from Node and Resolved onto a
   `FlexTree`, with the Inter width tables as a `TextFont`. The rules already match (rows,
   columns, stacks, gap, padding, grow, fill, min/max, wrap, scroll); the layout gains the
   caches. Android and web-document are untouched.
3. **The retained tree.** Rendering into abla-ui's tree instead of building a fresh Node
   tree each time gives the per-node change records (added, removed, moved, properties)
   a retained host needs: Android's Compose host could recompose only the changed nodes.
   This is the larger change: abla-one's string attributes and string-valued styles would
   map onto typed properties, and web-document's server rendering would serialize from
   the tree (keeping its HTML byte-stable). Breakpoints (`upTo`, `from`) and interaction
   states exist in both; theme scopes would be a theme per subtree.

A spike measured abla-one's current model on a settings-sized window (natively, release):
render 126 µs, render plus cached layout 190 µs, paint list 108 µs. The cost is in rebuilding
immutable trees and string-keyed styles each render, which step 3 removes.

## License

abla-ui is licensed under the [Mozilla Public License 2.0](LICENSE).
