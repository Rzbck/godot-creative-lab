# DC//LAB Design Review Checklist

Use this before validating a sketch as production-ready.

## Composition

- [ ] The visual has one clearly identifiable main idea.
- [ ] The focal hierarchy is obvious in a frozen frame.
- [ ] Negative space feels intentional.
- [ ] Alignment relationships are deliberate.
- [ ] Repetition/rhythm is controlled.
- [ ] Cropping is intentional, not accidental overflow.
- [ ] The composition still works at parameter minimum and maximum values.

## Margins and framing

- [ ] A logical safe area is defined when the design needs one.
- [ ] Glyph/image visual bounds—not only anchor points—respect the safe area.
- [ ] Distortion, blur, glow, chromatic split and motion amplitude are included in margin calculations.
- [ ] Edge interactions have been tested.
- [ ] Bleed/crop behavior is explicit.

## Typography

- [ ] Type role is defined: information, display, texture, navigation or image/material.
- [ ] Baselines and optical alignment are controlled.
- [ ] Kerning/tracking/word spacing feel intentional.
- [ ] Density changes recompute spacing and size coherently.
- [ ] Line length and leading are controlled where text must be read.
- [ ] Hierarchy survives motion/deformation.
- [ ] Variable-font axes stay inside valid ranges.
- [ ] Multi-script assumptions are documented if the sketch only supports Latin.

## Color

- [ ] Palette has semantic roles, not only arbitrary colors.
- [ ] Luminance hierarchy works.
- [ ] Saturation has hierarchy.
- [ ] Text remains legible against animated backgrounds when it must be read.
- [ ] Color is not the only carrier of essential information.
- [ ] Projector/monitor black level and brightness have been considered for installation use.

## Motion

- [ ] Motion has a small, consistent grammar.
- [ ] Primary motion is distinguishable from ambient motion.
- [ ] Timing has pauses/holds, not only perpetual movement.
- [ ] Transitions preserve continuity or break it deliberately.
- [ ] Motion does not make required text unreadable.
- [ ] Extreme interaction/audio values do not create uncontrolled flashing/jitter.

## Interaction

- [ ] Pointer/touch response is spatially consistent.
- [ ] Corners/edges/center are tested.
- [ ] Press, drag and release states are all intentional.
- [ ] Interaction has obvious visual causality.
- [ ] Recovery/idle behavior is designed.
- [ ] Touch works on the actual PROGRAM screen, not only the editor preview.

## Realtime / technical

- [ ] Preview and PROGRAM show the same composition/state.
- [ ] Preview optimization does not alter simulation seed/layout/phase.
- [ ] Logical layout is separated from physical output resolution.
- [ ] Resize/aspect-ratio changes do not destroy hierarchy.
- [ ] No debug labels or sketch metadata are burned into PROGRAM output.
- [ ] Settings persist between sessions.
- [ ] LIVE OUT remains independent from editor navigation.
- [ ] The sketch remains responsive while PROGRAM is active.

## Gallery / library

- [ ] Static thumbnail is representative.
- [ ] Hover preview is useful but not expensive when idle.
- [ ] Tags accurately describe technique/aesthetic/interaction.
- [ ] Primary tag places the sketch in a useful automatic group.
- [ ] Search terms can find the sketch by concept, technique and visual family.

## Installation / physical output

- [ ] Viewing distance is considered.
- [ ] Physical screen/projector aspect ratio is tested.
- [ ] Touch coordinate mapping is correct on the chosen display.
- [ ] Bezel/gap/surface boundaries are considered if multi-screen.
- [ ] Ambient light and contrast are acceptable.
- [ ] The work has a graceful idle state.

## Frozen-frame test

Capture or pause at several arbitrary moments. Every frame does not need to be a perfect poster, but repeated ugly accidents indicate the generative rules are under-designed.

Ask:

- Is hierarchy still visible?
- Are margins clean?
- Does the palette still work?
- Is there a focal point?
- Is the frame recognizably this sketch?

## Failure-mode test

Explicitly test:

- smallest supported app window;
- largest grid density;
- largest type/lens/effect radius;
- maximum chromatic displacement;
- pointer at all four edges;
- PROGRAM on every available screen;
- rapid project switching while another source remains live;
- restart and settings recall.
