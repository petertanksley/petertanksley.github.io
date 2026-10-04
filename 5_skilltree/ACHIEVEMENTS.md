# Achievements: the Dungeon Crawler Carl register, and how it maps here

Reference and design note for `data/achievements.yml` and `R/check_achievements.R`. Compiled 2026-09-19
from the DCC fan wiki (Floor 1 list, Achievement and Loot Box mechanics pages, individual achievement
pages; fetched through the wiki's MediaWiki API, the HTML being behind a Cloudflare wall) and Raymond
Camden's 2026-04-01 post, which generates DCC-style achievements with an LLM and is useful only for its
output shape (title / text / rewards list).

## The shape of an achievement in the books

Every one has four parts, in this order:

1. **Header.** `New achievement! <Title>.` The very first one a crawler gets reads
   `Congratulations! You've earned your first achievement: <Title>.`
2. **Title.** Short. Three shapes:
   - a label: *Early Adopter*, *Loner*, *Empty Pockets*, *Crazy Cat Lady*
   - a second-person past-tense statement of the feat: *You've Killed a Mob*, *You've Entered a Guildhall*,
     *You've Discovered and Read an Official Dungeon Sign*
   - a question or exclamation: *Why Aren't You Wearing Pants?*, *Boom!*, *Level-Up, Baby!*, *It Burns, Dunnit?*
3. **Body.** One to three sentences, second person. States the fact flatly, then mocks.
   - "You entered the dungeon wearing no pants. Dude. Seriously?"
   - "You are one of the first 5,000 Crawlers to enter a new World Dungeon. Sucker."
   - "You're a murderer! He probably had a family!"
   - "Congratulations. You know how to open doors."
   - "Wow. You can read. Whoopie."
4. **Reward line.** Always present, always begins `Reward:`. Two kinds:
   - a box: `Reward: You've received a Gold Apparel Box!` Six tiers, ascending: Bronze, Silver, Gold,
     Platinum, Legendary, Celestial. The box *type* is themed to the feat (Pet Box for the cat, Apparel Box
     for the pants, Weapon Box for fighting unarmed, Shoe Box for feet, Goblin Box for explosions,
     Survivor's Box for finishing a boss nearly dead, Asshole's Box for atrocities).
   - a non-box reward that is itself the joke:
     - "Reward: None! Haha. You are so dead."
     - "Reward: Leveling up is your job. You don't get rewards for doing your job."
     - "Reward: That sense of fulfillment you feel? That's reward enough."
     - "Reward: It's probably going to hit back."
     - "Reward: You're now a handsome son of a bitch. That's reward enough."

## What earns what

| Kind of feat | Example | Reward tier |
|---|---|---|
| Doing the routine thing | reaching level 2; entering a guildhall; taking damage | none, with mockery |
| First time you do X | first kill, first loot, first safe room, first magic gear | Bronze (occasionally Silver) |
| Doing X badly or oddly | no pants, no weapon, no supplies, punching a slime | Bronze to Gold, the joke sets the tier |
| Crossing a count | first 5,000 crawlers; >15 mobs in one attack; >1 ton in inventory | Silver to Gold |
| Being the *first crawler ever* to X | first to enter with a cat ("Trailblazing") | Legendary |
| Celestial | almost never awarded; bankrupts the host | reserve it |

Design principle stated outright on the mechanics page: the tutorial floors *drown* you in low-tier boxes for
mundane feats, so you keep playing; later, achievements get rare and personal. The System AI is
"always listening", and rewards or withholds at its discretion. Mockery is the constant; the box is optional.

## Mapping to this site

Our "floor" is the citation record and the publication list. Snapshots in `data/scholar/` are the only
sensor; rules in `data/achievements.yml` are the System AI.

**Structure per rule** (implemented 2026-09-19 in `data/achievements.yml`): `title`, `body` (one or two
sentences, the fact then the mock) and `reward`, which is either a joke line or `{type, tier}`; `tier` may be
a ladder of `{at, tier}` rungs read against the new value. `check_achievements.R` renders
`Reward: You've received a {tier} {type}!` for boxes, so only joke rewards are hand-written.

**Ledger** (implemented): `check_achievements.R --log` writes every fired achievement, fully rendered with
metric, old and new values, snapshot date, `key` (id + date, the page anchor), `paper` (title, for the byline),
`rank` (tier index; sorts within a date) and `featured` (from the paper), to `data/achievements_log.yml`
(committed). The site renders from the ledger, never from the rules. **Entries are archival** (Peter,
2026-09-27): once written they are never re-rendered, so a wording edit, a new variant (which shifts the hash pick)
or a moved rung applies only to achievements earned afterwards, as in the books. `--replay` re-runs every
consecutive snapshot pair but keeps every key already in the ledger verbatim, including entries today's rules would
no longer fire; it only renders and adds keys the ledger lacks (a rule added after the snapshots). `--replay --fresh`
is the one way to rewrite history from today's rules.

**Tier logic** (as implemented for the four current rules; extend by adding rules):

| Trigger here | Books analogue | Tier |
|---|---|---|
| `step` on h-index or i10 | levelling up, "your job" | none: a joke reward |
| `ladder` on h-index 15 / 20 / 25 / 30, and on i10 20 / 30 / 50 / 100 (added 2026-09-27) | crossing a count the committee notices | Silver, Gold, Platinum, Legendary; Committee Box |
| `ladder` on any single paper's citations, quarters 1 / 10 / 25 / 50 / 100 | first kill, then crossing counts | Bronze (lead-author papers only), Silver, Gold, Platinum, Legendary |
| `ladder` on a root paper's descendants (`lineage`, from `builds_on`), 1 / 3 / 5 / 10 | founding a guild | Silver, Gold, Platinum, Legendary; Heirloom Box |
| `ladder` on a paper's OpenAlex year percentile, 97 / 98 / 99 / 100, papers two calendar years old (`min_age`) | "first crawler to": relative standing | Silver, Gold, Platinum, Legendary |
| `round every: 100` on total citations | crossing a count | Silver at 100s, Gold at 500, Platinum at 1000 |
| `revival` on a dormant paper's OpenAlex count (Necromancy, 2026-10-03) | raising the dead | Gold, flat; Phylactery Box (Archive Box on mortality papers) |
| hand-logged events (`trigger: manual`, 2026-10-03) | Benefactor boxes, boss kills | talk Silver, grant Gold, award Platinum, media Bronze, IRB first try Legendary, tenure Celestial |
| `step` on `career.reviews`, forward only (2026-10-03) | doing the job anyway | Bronze Reviewer 2 Box, every review |
| `ladder` on `career.reviews` 10 / 25 / 50 / 100 | crossing a count | Bronze at every rung: reviews have a Bronze ceiling, ever |
| `ladder` on `career.articles` 10 / 20 / 30 / 50 / 100 | crossing a count | Bronze, Silver, Gold, Platinum, Legendary; Bibliography Box |
| Celestial | never | tenure, if it comes; nothing else |

Peter, 2026-09-19: "attainable, not rock-star." With 30 papers (7 at zero, 8 at one to nine, 15 at ten to
ninety-nine, none at a hundred) the per-paper log10 rule is what keeps the dungeon noisy: seven papers are
one citation from Bronze, eight within a few of Silver, the leader at 64 has Gold in view. The single-paper
"first blood" rule was folded into it; the checker expands `articles.*.` metrics over every paper and picks
the box type from the paper's dominant area (Flask, Handcuff, Challenge Coin; Adventurer on a tie).

Why quarters, not log10 (2026-09-19): log10 left fifteen papers queued for Gold and nothing above it reachable.
Under quarters the next rungs spread 7 / 8 / 6 / 8 / 1 across Bronze to Legendary.

**Percentile rule.** OpenAlex's `cited_by_percentile_year` ranks a work among *all* OpenAlex works of its
year, most of which are never cited, so it runs high: a 4-citation 2021 paper sits at 89, a 42-citation 2022
paper at 93 (conservative end of the band). Hence rungs in the nineties, and `fetch_scholar.R` records the
percentile only once the paper has a full calendar year behind it, because in the publication year the cohort
is mostly empty and the band is inflated. Achievements only fire upward; a percentile that later slips does
not un-earn anything. Peter, 2026-09-20, after the first refresh fired twelve of these: too plentiful. The rule
now waits until a paper is two calendar years old (`min_age: 2`, judged at the snapshot date; a paper too young
at the old snapshot counts as 0 there, so its first eligible snapshot fires the rung it sits on) and starts at
the top 3% (97 Silver, 98 Gold, 99 Platinum, 100 Legendary; no Bronze, because top 3% is not a Bronze feat).
Against the 2026-09-20 data that leaves one: the 2023 Clinical Psychological Science paper at 98, Gold.

**First-citation Bronze is lead-author only** (Peter, 2026-09-20): a rung may carry `role:` and then exists only
for papers of that role, so a contributing-author paper's ladder starts at Silver, ten citations in. Seven papers
sat one citation from Bronze; that would have been the next flood.

**Founder** (Peter, 2026-09-20: "achievements for papers that are the start of a lineage"). `fetch_scholar.R`
writes `articles.<id>.lineage` into every snapshot: for a paper with no `builds_on` of its own, the number of
papers downstream of it (children, grandchildren ...); 0 for anything mid-lineage. The rule ladders it 1 / 3 / 5 /
10 = Silver / Gold / Platinum / Legendary, Heirloom Box. Lineage is static data, so this fires when a new paper
is added with a `builds_on`, i.e. on the refresh after `add_article.R`. The 2026-09-20 snapshot was backfilled
so the three existing roots (LEO mortality 2025, Gonzalez 2025, Raffington 2022; two descendants each) fired then.

**Necromancy** (Peter, 2026-10-01; built 2026-10-03). A paper is dormant at a snapshot when it is at least three
calendar years old and has no citations in the last complete calendar year *or* so far in the current one; the next
snapshot that shows its OpenAlex count rise, with the new citations landing in that window or later in `by_year`,
raises it. The current-year condition keeps a paper that already woke up from firing again on every later snapshot;
the `by_year` condition guards against OpenAlex dedup jitter. One flat Gold box (no ladder on how long it was silent;
the body says how long, `{silent}`). A paper can rise again if it dies again, since the key carries the date. Data:
`fetch_scholar.R` stores OpenAlex `counts_by_year` as `articles.<id>.by_year` (`{"2023": 4, ...}`; `{}` = never cited,
`null` = no record). Snapshots before 2026-10-03 lack it, so nothing fires across them. **Guardrail:** papers tagged
`mortality` in `articles.yml` (`tags`, a judgement field `extract_cv.R` preserves) take the rule's `by_tag` wording:
the paper wakes, is dusted off, turns up in the archive; never rising-from-the-dead imagery near a paper about people
who died. Same "first blood" problem as 09-19.

**Forward only** (Peter, 2026-10-03): achievements pop up as things happen. No dump of the past on entering the
dungeon. The one exception is a cumulative milestone (30th article, 50th review), which counts the whole history and
may fire once, at the rung already reached, on the first snapshot that records the count. Per-event rules on a new
metric carry `forward_only: true`, so they stay silent until the metric has a previous value.

**Manual achievements** (Peter, 2026-10-01; built 2026-10-03). `data/achievements_manual.yml` is append-only, one
entry per event `{kind, date, what, where, note?, approx?, slug?}`, logged as it happens (no CV backfill). Each
`kind` is a `trigger: manual` rule in `achievements.yml` (same register: title variants, fact then mock, reward).
`--log` renders events not yet in the ledger (key `<kind>-<date>-<slug>`, `source: manual`); `--replay` keeps them as
written like everything else. `approx: month | year` covers a date known only that precisely; the ledger then carries
`when`, which the page prints in place of a day, and a date group of events is labelled *Event*, not *Snapshot*.
Manual entries have no `article`, so they sit on the origin's character sheet. R&R and desk-reject kinds were
planned and dropped the same day (Peter: they would never get logged).

**Career counts and reviews** (2026-10-03). `fetch_scholar.R` writes `career: {articles, reviews}` into each
snapshot from `data/career.yml`: articles = CV-numbered entries in `articles.yml` (published + in press), reviews = rows
of the `/bob review` card's `## Archive` table, one per submitted round (so `/bob review done` is all it takes; history
back to 2024 reconstructed into the table 2026-10-03, 16 rounds). **Only the count is ever published**: no journal, manuscript id or submission date reaches the
snapshot, ledger or site, and a review achievement is dated to the refresh, because a public journal + date could let
an author identify a blind reviewer. If the card is unreachable, the previous count is kept with a warning.

**Box types**, themed to the feat as the books do. In use: Appendix Box (total citations), Flask Box /
Handcuff Box / Challenge Coin Box (per-paper, by domain, matching the phase stickers), Adventurer Box (tied
domains), Heirloom Box (starting a lineage), Committee Box (h-index and i10 milestones, 2026-09-27), Phylactery / Archive Box
(Necromancy), Reviewer 2 and Bibliography Boxes (career counts), and for manual events Podium, Grant (Benefactor
analogue: someone else paid), Laurel, Soundbite, Protocol and Tenure Boxes (2026-10-03). Not yet used: Coauthor Box, Postdoc Box (junk tier by definition).

**Rendering** (2026-09-20; Peter: gold numeral, career achievements on the origin, achievements separate from
the news stream). Four surfaces, all reading the ledger:

- `achievements.qmd` + `achievements-listing.ejs`: every entry as a system message (header, title, paper byline,
  body, Reward line) on the dark page, grouped by snapshot date, tier colour on the left rule, `#<key>` anchors,
  "Find the hex" linking to `skilltree.html#<article>`. Nav: Research ▸ Achievements.
- `index.qmd` + `achievement-home.ejs`: one dark card under News with the newest *featured* entry (the two
  biomarker papers are `featured: false` and never headline) and the total as a roman numeral. `news.yml` is
  untouched; a big achievement can also get a hand-written news line.
- The tree (`build_tree.R` → `tree.json` → `skilltree.js`): per paper `achievements {n, best, items}` drawn as a
  gold roman numeral upright in the hex's bottom corner, opposite the pips; an Achievements
  section in the panel (tier chip + title, linking to the page); the legend and a fourth stats-card figure.
- Career-level entries (no `article`: h-index, i10, total citations) ride on `meta.origin.achievements`:
  Achievements section on the character sheet only. No numeral on Peter's hex (Peter, 2026-09-27: every
  achievement is his, so a count there marks nothing).

Titles are the joke, as in the books ("Patient Zero.", "Please Stop Refreshing Google Scholar."), vaguely about
the feat and never the bare fact; the body carries the fact (Peter, 2026-09-20). The paper is named by the `paper`
field, printed as a byline on the page and card but not in the panel, which is already the paper.

**Variation** (Peter, 2026-09-20: "vary the language up so the same achievement doesn't have identical text").
`title`, `body` and a joke `reward` may each be a list of variants; the checker picks one per firing with a
hash of the achievement key (rule + paper + snapshot date), so the same feat reads differently across papers and
dates while `--replay` reproduces the ledger exactly. Peter asked for the clock as the seed; refused, because a
clock seed would rewrite every past achievement on replay. Three variants each at present; add more freely.

**Voice guard.** The books swear and go crude; this site is dry, not zany (CLAUDE.md). Keep the fact-then-
mock rhythm, drop the profanity. Never sass about responders dying; sass about the job, the appendix,
peer review, and Peter.

## Sources

- https://dungeon-crawler-carl.fandom.com/wiki/Floor_1_Achievements (and `/wiki/Achievement`, `/wiki/Loot_Boxes`,
  individual achievement pages). HTML is Cloudflare-walled; `api.php?action=parse&page=<Title>&prop=wikitext`
  serves the wikitext without a challenge.
- https://www.raymondcamden.com/2026/04/01/youve-gained-a-new-achievement
