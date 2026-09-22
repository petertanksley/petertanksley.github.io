# 2026-09-22 — Trapdoor scene for the landing page

Second wide pixel-art scene after the hearth (`logs/2026-09-01_sticker-generation.md`). Now at the
foot of `index.qmd`, styled by the `.scene-figure` alias of `.hearth-figure` in `theme.scss`.

## Brief (Peter)

Composition borrowed from the *Holes* movie poster: camera at the bottom of a hole, a ring of faces
peering down. Here the hole is the trapdoor from the basement apartment into the sub-basement lab,
the faces are Peter, Josie, Winnie and the skull, all puzzled and a little worried at whatever is
down there with the camera. Ladder coming down out of the hatch. 16:9 to match the hearth slot.

## Rounds

| Entry | Fix attempted | Result | Cost |
|-------|---------------|--------|------|
| `trapdoor` | first roll; poster described in words, not attached | all three strong; one drew Josie twice; **rug on the apartment ceiling** because the prompt asked for "a rug at the rim", which a camera below the floor cannot see | $0.20 |
| `trapdoor2` | view through the hatch rewritten as the apartment ceiling (beams, plaster, firelight wash) | ceiling correct; **open flames directly behind the skull** in all three despite "no flame is visible"; beard drifted red; lid drawn hanging down into the lab | $0.20 |
| `trapdoor3` | no-flames rule moved to the front and repeated behind the skull; beard "walnut shell, no red/orange/ginger/copper" up front; lid "swung UP and away, lies flat on the floor above, not visible" | lid gone in all three; fire down to an orange wash in two of three; beard half a shade browner, still ginger under firelight | $0.20 |

Winner: `trapdoor3-3` (Peter). Square archived to `finals_src/trapdoor.png`, JPEG at `www/trapdoor.jpg`
(sips, quality 88; `magick` CLI is not on this Mac, the R package is).

## Lessons

- **Write what the camera can see, not what is in the room.** A low camera sees ceilings. Anything
  named in the prompt gets drawn somewhere in view, so a floor detail ends up on the ceiling.
- **Negations late in a long prompt are ignored.** "No flame is visible" buried mid-prompt produced
  a bonfire; the same rule stated in the first two sentences and repeated at the object got a glow.
- **Physical mechanisms need stating.** The model hinged the trapdoor lid downward into the lab in
  every round until told it swings up and lies on the floor above.
- Beard colour: three rounds of correction bought about half a shade. The hearth ref's firelight
  keeps pulling it ginger. Accept, or attach a neutral-light headshot as the face ref next time.
- Palette anchoring on the hearth output (`refs/hearth_scene`, gitignored) kept all nine candidates
  matched to the About scene without any other style text.

## Placement decision

Landing page bottom over Projects or About: the camera position makes the visitor the thing in the
sub-basement, which only lands at the end of the homepage. About would stack two scenes and the
hearth would lose. Projects page remains a candidate for a future scene. Caption (Peter picked):
"You've reached the bottom of the page. So has everyone else."

Spend today: $0.61.
