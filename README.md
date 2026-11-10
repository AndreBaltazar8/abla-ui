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
| `src/text.ab` | Line breaking over any font (`TextFont`): spaces, long words, newlines, max lines with an ellipsis. `TableFont`: a font from per-weight advance tables, for measuring with no renderer (a server laying out HTML). |
| `src/style.ab` | Styles as ordered (condition, property, value) entries, the last match winning: interaction states (hover, pressed, focused, selected, disabled) and viewport breakpoints (`upTo`, `from`); raw (name, value) entries a backend passes through untouched (`raw("css:color", "red")`). Resolved paint (`Look`) and the theme (`Theme`, with named styles and named scopes; `withTheme` builds a subtree with another). |
| `src/tree.ab` | The retained tree: elements (`El`) from components' `render()`, reconciled by key into nodes that keep their layout, look and wrapped text; per-node change records (added, removed, moved, properties); the paint walk onto a `ViewPainter`; per-frame changes without a render (`setText`, `setTranslate`, `setOpacity`, `setValue`). |
| `src/input.ab` | Input over the tree: hit testing, hover and press, sliders, focus navigation (Tab, arrows, Enter / Space, the pad), scrolling (wheel, drag), Escape closing the topmost window, tooltips. |
| `src/kit.ab` | Window, panel, button, toggle, slider, tabs, label, caption, list, list row, tooltip, built from elements and the theme. |
| `src/markup.ab` | What the tag syntax compiles to: attributes read as style properties, colours and keywords. |
| `src/ui.ab` | Imports all of the above. |
| `src/dsl.ab` | `$ui`: the tag syntax (import it where templates are written; one module is `github("AndreBaltazar8/abla-ui/dsl")`). |

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

### The same window in the tag syntax

`$ui` is abla-one's `$one` syntax (its parser, ported): one element per template, attributes
as style properties unless the element takes them as data, `state:` and `max760:` prefixes,
`{expressions}`, `on*={ statements }` handlers (`onChange` receives `value`), `<If>` /
`<Else>` / `<For>`, and capitalised tags calling a function of that name. The tag syntax
(`dsl`) needs ablac 0.2.53 or newer; the rest of abla-ui builds with 0.2.48 and newer.

```abla
import github("AndreBaltazar8/abla-ui")
import github("AndreBaltazar8/abla-ui/dsl")

class SettingsWindow() : Component {
    fun render(): El = $ui
        <If cond={settings.open}>
          <Window title="Settings" onClose={ settings.open = false } width=360 anchor="center">
            <Label>Volume</Label>
            <Slider value={settings.volume} min=0 max=1 onChange={ settings.volume = value }/>
          </Window>
        </If>
}
```

A capitalised tag that isn't built in is a program's own: a function giving an element, or a
class implementing `Component`, which is mounted under the tag's `key` (its name unless
given) and keeps its first instance, and so its State, while its parent renders again. Each
attribute goes to the parameter of that name, in any order, and a parameter with a default
may be left out; the compiler reports an attribute that names no parameter, one given twice,
or a required one missing, at the tag. A tag's children go to the parameter named
`children` (`array<El>`), so a function that takes children must call that parameter
`children`. A prefixed attribute (`hover:gap`) is style, which a custom tag doesn't take:
pass a `Style` through a parameter instead.

```abla
fun Card(title: string, children: array<El>, width: f64 = 200.0): El = $ui
    <Column width={width} gap=6>
      <Text>{title}</Text>
      {fragment(children)}
    </Column>

class Counter(val label: string, var clicks: int by State(0)) : Component {
    fun render(): El = $ui
        <Button onPress={ clicks += 1 }>{label} {clicks}</Button>
}

fun Toolbar(): El = $ui
    <Row gap=8>
      <Card width={320.0} title="Fruit">
        <Counter label="apples"/>
        <Counter key="pears" label="pears"/>
      </Card>
    </Row>
```

Built in: `Column`, `Row`, `Stack`, `Box`, `Scroll`, `Pressable` (onPress), `Text`, `Label`,
`Caption`, `Button` (onPress), `Toggle` (value, onChange), `Slider` (value, min, max,
onChange), `Tabs` (labels, selected, onChange), `Window` (title, onClose), `Panel`, `List`,
`ListRow` (selected, onPress), `Image` (handle), `Spacer`. Every element takes `key`, `name`
(for `tree.named`), `tooltip`, `selected` and `disabled`.

Where it differs from `$one`, and why: handlers are closures on the elements, so no `ui: Ui`
needs to be in scope; colours are `"#rrggbb"` / `"#rrggbbaa"` or `@text` / `@muted` /
`@accent` (abla-ui's styles are numbers, not strings the theme resolves later); abla-ui's own
properties are there too (`chamfer`, `glow="8 #e9b866 0.3"`, `shadow="18 6 0.45"`, `gradient`,
`anchor="top-right"` with `offsetX` / `offsetY`, `solid`, `textEffect`); `size` is a box's
width and height (`fontSize` sizes text); a target prefix (`web:`) keeps an attribute only
where `uiTarget` names that target (abla-forge is `forge`).

A frame where nothing changed renders no component, lays out no node, measures no text
and resolves no style: painting is one walk over cached boxes and text lines. A State
change re-renders only the components that read it; a per-frame value (an fps counter, a
name tag over a character) goes through `tree.named(...)` and `setText` / `setTranslate`
without any render.

A read works through any reference (a `val`, an immutable parameter, a field of an immutable
object): who read a State is kept in a table by its id, not in the State, and only while a
render scope has read it (a State nobody reads under a scope keeps nothing global). State is
confined to one thread: a `thread { }` that touches one doesn't compile. State holds plain values (numbers, booleans, strings). Keep a collection beside a State
that counts its changes, and bump it after each edit.

## Order is deterministic

Whatever a backend reads (a node's children, its style entries, raw entries, change records,
paint calls) comes out in program order: the order things were written, declared or
reconciled. Nothing a backend reads iterates a Map or depends on an address or a hash; the
tree's one Map (names, for `named`) and the theme's (named styles and scopes) are only
looked up. `tests/style_test.ab` builds the same tree twice and checks the paint calls and
change records match call for call.

## Data from a wire takes defaults

abla-ui decodes nothing from a wire today. Anything it ever decodes (a State restored from
storage, a tree or patch sent between a server and a host) must read a field that is absent
as its default when it has one, and ignore fields it doesn't know: a newer side then still
talks to an older one when a message gains a field. Only a field with no default may make a
message invalid.

## Checks

`scripts/test.sh` builds and runs every `tests/*_test.ab` natively, and checks that every
`tests/errors/*.ab` fails to build with the message its `// expect:` line names (`ABLAC` picks
the compiler). abla-ui builds with ablac 0.2.48 and newer; the tag syntax (`src/dsl.ab`) needs
0.2.53 or newer, and with an older compiler its checks are skipped.

## One grammar

`src/dsl.ab` is `$one`'s parser with abla-ui's element table: the grammar (tags, attributes,
prefixes, handlers, text content, `<If>` / `<Else>` / `<For>`) is the same code, and only the
table of what each tag compiles to and the runtime names differ. It depends only on
`abla/compiler/parser`, so the end state is one parser in abla-ui taking the element table as
a parameter, with `$one` and `$ui` both registered from it.

## License

abla-ui is licensed under the [Mozilla Public License 2.0](LICENSE).
