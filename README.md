# master mod

An [open-field](https://github.com/LaP0573/open-field) pack for the Teenage Engineering OP-1 Field running OS 1.7.3. It remaps the four Master-page encoders, moves the master compressor's L/R post-makeup inside each drive stage so the L and R faders act on the compressed output, and ships two matching SVGs that coexist cleanly with other packs.

Format 3 pack, built against open-field 0.12 and firmware 1.7.3.

## What it does

### Master page

| Encoder | Colour | Stock role | `master mod` role |
|---|---|---|---|
| 0 | blue `#4878A8` | L fader | **DRIVE** |
| 1 | ochre `#8A653C` | R fader | **RELEASE** |
| 2 | gray `#5B6670` | DRIVE | **L fader** |
| 3 | red `#E52817` | RELEASE | **R fader** |

- **Shift + gray** or **Shift + red**: links L and R (they move together).
- **Shift + blue** or **Shift + ochre**: neutral (a stock quirk is neutralised).
- The other Master subscreens (Volumes, EQ, FX) are strictly stock, not touched.

### Master compressor

- Threshold, ratio, attack and release: strictly stock (−6 dBFS threshold).
- **Per-side post-makeup**: the fixed ×1.5 output gain of each of the 4 drive stages becomes `×1.5 · L²` on the left channel and `×1.5 · R²` on the right. The L and R faders modulate the compressed output instead of the pre-gain, which makes gain-staging the master much more musical.

### Pictures

- **`master.svg`** (always applied): the Master page's picture is updated to match the new encoder roles — colour permutations, L/R faders moved under MASTER, DRIVE/RELEASE labels moved left.
- **`signalflow.svg`** (conditional): the fader pills and level digits of Master L/R on the Shift+Mixer screen are swapped to gray/red, matching the Master page. **Only applied when `sidechain.pack` is absent**, so sidechain's own duck page keeps working when installed. The coexistence is handled by a `pick` callback in the pack code that weak-imports `op1f_duck_screen` from sidechain and steps aside if it's there.

## Install

1. Install open-field 0.12 on your Field via the official page: https://lap0573.github.io/open-field.
2. Drop `out/master mod.pack` into `user/pk/` of the Field (via disk mode or an MTP tool like [mtp1f-web](https://seajaysec.github.io/mtp1f-web/)).
3. Reboot. The start screen should read `1.7.3 - open-field 0.12` and the Master page should show the custom artwork.

**Recovery**: hold the Help key at boot to start without any pack (non-destructive). Delete `master mod.pack` from `user/pk/` and reboot to remove it definitively. Full return to the stock TE firmware: re-flash the stock LDR via the open-field page builder.

## Coexistence with other open-field packs

- **`sidechain.pack`** (official): handled. Our `signalflow.svg` steps aside via the `pick` callback when sidechain is loaded, so sidechain's signal-flow page (ducks, targets, VU) is served normally. We lose the gray/red fader pill colouring in that case — the master.svg encoder remap is unaffected.
- **`fx train.pack`** (official): no known conflict.
- **`lfo.pack`** (official): no known conflict.
- **`8 tracks.pack`** (official): no shared firmware places, no theoretical conflict. Not yet tested on a Field running both.

## Technical summary

- **14 firmware places**: 2 DDR (`0x8c0bb5d4` and `0x8c0bb63a` in `sub_8c0bb294`, Master-page input dispatch) + 12 L1 places in the master compressor function at `0x11a08350` (4 LR_PRE + 8 LR_POST15). All places verified against stock `d134eb1a…fad0ec` via `tools/place_sum.py`.
- **Inline trampoline technique** on all 12 L1 places: `copies=0`, the routine emulates the patched bytes verbatim and ends with an inline 8-byte `JUMP.a` back to the next stock instruction boundary. No P-register touched, no stack used — safe for the audio thread. Measured overhead: approximately 0.08 % per audio block.
- **1 level-1 card** with an empty frame function and a `pick` callback (`master_mod_pick` in C++).
- **Pack format 3** for open-field 0.12.

## Rebuild from source

In a clean clone of [`LaP0573/open-field`](https://github.com/LaP0573/open-field) at a release that targets firmware 1.7.3:

```
git clone https://github.com/etcetc000/open-xy open-xy
python open-xy/sdk.py toolchain fetch
mkdir examples/master-mod
cp -r <this-repo>/examples/master-mod/* examples/master-mod/
python -I tools/pack_build.py pictures --recipe examples/master-mod/recipe.json --out examples/master-mod/master-mod_pictures.s
python -I tools/pack_build.py card     --recipe examples/master-mod/recipe.json --out examples/master-mod/master-mod_card.s
python -I tools/pack_build.py build3   --recipe examples/master-mod/recipe.json --profile profiles/op1f-1.7.3.json --out "out/master mod.pack"
python -I tools/pack_build.py check    --pack "out/master mod.pack"
```

The `svg-kit/` folder of this repo keeps the stock-vs-custom SVG pairs used to regenerate the `.make` files:

```
python svg-kit/make_builder.py svg-kit/master-stock.svg     svg-kit/master-custom.svg     master.svg     examples/master-mod/master.svg.make
python svg-kit/make_builder.py svg-kit/signalflow-stock.svg svg-kit/signalflow-custom.svg signalflow.svg examples/master-mod/signalflow.svg.make
```

## History

Developed under the working name `master-output` across 8 iterations in November 2026, renamed `master mod` for the public release to align with the naming style of the official open-field packs (`base`, `8 tracks`, `fx train`, `lfo`, `sidechain`). First published version is `1`, binary-equivalent to the `master-output v8` of the development history.

## License

MIT. See [LICENSE](LICENSE).

## Credits

- Built on top of [open-field](https://github.com/LaP0573/open-field) by LaP0573, which provides the loader and pack framework for the OP-1 Field.
- Pack author: Reverdy-Carrasco.
