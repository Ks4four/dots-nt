# dots-nt
man hope this fits on my tombstone

## styleNotes

i prefer plain text.
if you want to know why, check this piece: `https://ks4four.github.io/life/software/markdown/`

## jwno

thinking about `modalEditing` in a `windowManager`... so that i don't need `workspaces` concept.

`jwno` is natively a manualTilingWindowManager. the official example uses a stackBasedKeymap.
but i believe with enough janet, you can program it to behave however you want.

this config attempts to turn a `manualTiler` into a `modalEditing` mnemonic (not a real system), just like meow (`https://github.com/meow-edit/meow`) but for windows.

note that this config is 100 percent written by ai. i literally didn't write a single character.

why in this config:

meta:\
everything in this config assumes `:viewport` is enabled. all behaviors are designed around this. it is the infiniteCanvas: your monitor is just a camera looking at an infinite plane. you don't "switch workspace", you `:scroll-parent`. this is definitely not an alternative to "workspaces" concept.

why not "workspaces":\
i have to admit, "workspaces" is a more robust concept. my reason is simple: my keyboard lacks a numrow, so i simply don't use them. actually, prompting the ai to implement "workspaces" logic that talks to yasb shouldn't be hard. after implementing this nonWorkspace approach, i realized that sticking to "workspaces" demands a specific mental loop: recall which "workspace" an app resides in, then press `mod` key + `#` numbers to switch. this fundamentally violates `selectFirstOperateLater`: you are forced to `operate` (context switch) before you can even `select` the target window.

why arrows not "h"/"j"/"k"/"l" keys:\
i designed the inputs based on the nature of the operation. left/right arrow keys mean continuous values, while "h"/"j"/"k"/"l" keys is regarding windows. this bypasses the granularity conflict of using "h"/"j"/"k"/"l" keys for everything. for example, in `RESIZE`, `SCROLL`, and `ALPHA` modes, you can use "h"/"j"/"k"/"l" keys to change focus, then use arrow keys to `rapidFire` adjustments. i have a keyboard with a knob, but mapping clockwise/counter clockwise to "h" key and "l" key feels weird. left and right arrow keys don't have this issue. keymap also has logic regarding semantic modifiers. for example, "h"/"j"/"k"/"l" keys is always about `frame`s. keys with modifiers like "Ctrl" key + "h"/"j"/"k"/"l" key is `window`s.

why choose inspired by meow, not vim:\
unlike standard `windowManagers` (and unlike `vim`'s `d2w` command), the logic here is selectFirstOperateLater. it's like meow/helix/kakoune. the idea is simple: since the window is always focused, naturally, this is a selection state. it fits `selectFirstOperateLater`, rather than vim's `verbThenNoun`.

why "F23" key:\
actually, "F23" key is just personal preference. it can be totally substituted with any other key.

why `:set-keymap` and not `:push-keymap` or why this keymap:\
in `jwno` documentation, these behave like `transientKeymaps`. in `zmk` terms, it's a `&toggle` layer. personally, managing multiple `&toggle` layers messes up my brain (too much cognitiveLoad), so i restrict `F23` as the sole `&toggle`. this way i only maintain one mental layer (another `zmk` concept: `https://zmk.dev/docs/keymaps/behaviors/layers`). no matter the current `mode`, pressing `F23` key instantly exits to `PASSTHROUGH`. that is the desired behavior. however, the real reason is that this config requires jumping between arbitrary `mode`s, and the ai seemed incapable of generating a working config using the stack-based `:push-keymap` logic, so i prompted the ai to use the imperative approach.

why design jumping between different modes:\
so that i can operate applies immediately to the selection: in `RESIZE` or `ALPHA` modes, "h"/"j"/"k"/l keys (selection) and arrow keys (adjustment) can be pressed almost simultaneously.

why `yasb` is a must:\
`yasb` is needed to show `mode`s. also, visualising the depth calculation and the index of window-in-frame is quite necessary.

how to work with `yasb`:\
here we just use a temp file to do `interProcessCommunication`. current state is serialized to `jwno-status.json` in real-time, so external widgets (`yasb`) can render the ui reactively without polling. this coincidentally fits the unixPhilosophy: doOneThingAndDoItWell. the `jwno-status.json` file is just a string payload that looks like this: `{"mode":"PASSTHROUGH","viewport":0,"timestamp":1764702210,"depth":0,"window":{"position":0,"total":3},"frame":{"position":1,"total":2}}`.

why temp file:\
for this tool combination, the optimal solution might be a udp socket. but the ai kept trying to use `(import net)`, which is too complex for me since it requires recompiling the binary. simply concatenating a `json` string is obviously much easier.

## zmk

wip

![Eyelash Corne Keymap](zmk/corne-eyelash/keymap-drawer/eyelash_corne.svg)