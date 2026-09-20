// skilltree.js — draws the publication skill tree from www/tree.json.
//
// No dependencies. R (R/build_tree.R) has already done the thinking: positions, regions, labels,
// links and contribution scores all arrive in the JSON. This file only puts SVG on the page and
// handles hover / focus / click. Keep it that way: logic belongs in R, not here.
//
// Interaction (Phase 1): hover or keyboard-focus a hex → tooltip with title, venue, role and the
// six contribution bars. Click / Enter / Space pins the tooltip (also how touch works); Esc or a
// click elsewhere unpins. The click → detail panel is Phase 2.

(function () {
  'use strict';
  const root = document.getElementById('skilltree');
  const tip  = document.getElementById('skilltree-tooltip');
  if (!root || !tip) return;
  // Quarto's content column is its own stacking context (z-index 998, opacity .999), so a fixed
  // panel inside it can never rise above the fixed-top navbar (1030). Portal the overlays to <body>.
  document.body.appendChild(tip);
  const panelEl = document.getElementById('skilltree-panel');
  if (panelEl) document.body.appendChild(panelEl);

  const NS = 'http://www.w3.org/2000/svg';
  const CREDIT_LABELS = {
    conceptualization: 'Conceptualization', data: 'Data', analysis: 'Analysis',
    methods: 'Methods', writing: 'Writing', supervision: 'Supervision'
  };
  const ROLE_LABELS = { lead: 'Lead author', contributing: 'Contributing author' };
  const STATUS_LABELS = { in_press: 'in press', preprint: 'preprint', published: '' };

  let pinned = null;   // the <g class="node"> whose tooltip is pinned, if any

  // --- tiny helpers ------------------------------------------------------------------------
  function svgEl(tag, attrs, parent) {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }
  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  }
  // point-up hexagon path centred on (cx, cy)
  function hexPath(cx, cy, w, h) {
    const p = [[cx, cy - h / 2], [cx + w / 2, cy - h / 4], [cx + w / 2, cy + h / 4],
               [cx, cy + h / 2], [cx - w / 2, cy + h / 4], [cx - w / 2, cy - h / 4]];
    return 'M' + p.map(q => q[0].toFixed(1) + ',' + q[1].toFixed(1)).join('L') + 'Z';
  }

  // --- tooltip -----------------------------------------------------------------------------
  const AREA_LABELS = { biosocial: 'Biosocial', criminology: 'Criminology', responders: 'First responder' };
  function areasText(n, areas) {
    return areas.filter(k => n.areas && n.areas[k] > 0).map(k => `${AREA_LABELS[k] || k} ${n.areas[k]}`).join(', ') || 'areas not rated';
  }
  function areasHTML(n, areas) {
    if (!n.areas || areas.every(k => n.areas[k] == null)) return '<div class="tt-unscored">Areas not yet rated.</div>';
    return '<div class="tt-areas">' + areas.map(k => {
      const v = n.areas[k] || 0;
      const dots = [1, 2, 3].map(i => `<i class="${i <= v ? 'on' : ''}"></i>`).join('');
      return `<span><span class="lab">${esc(AREA_LABELS[k] || k)}</span>${dots}</span>`;
    }).join('') + '</div>';
  }
  function tooltipHTML(n, credit, areas) {
    const jif = n.impact && n.impact.jif != null ? `${pipsHTML(n.impact.tier)}${n.impact.tier ? ' ' : ''}JIF ${fmtJIF(n.impact.jif)}` : '';
    const ach = n.achievements && n.achievements.n ? `<span class="num" title="${esc(achPlural(n.achievements.n))}">${roman(n.achievements.n)}</span>` : '';
    const meta = [n.year, n.venue, STATUS_LABELS[n.status]].filter(Boolean).join(' · ') + (jif ? ` · ${jif}` : '') + (ach ? ` · ${ach}` : '');
    const pos = (n.author_position && n.authors_n)
      ? `author ${n.author_position} of ${n.authors_n}`
      : (n.author_position ? `author ${n.author_position}` : '');
    let bars;
    if (n.scored) {
      bars = '<div class="tt-bars">' + credit.map(k => {
        const v = n.contribution[k] || 0;
        const cells = [1, 2, 3].map(i => `<span class="${i <= v ? 'on' : ''}"></span>`).join('');
        return `<span class="lab">${esc(CREDIT_LABELS[k] || k)}</span><span class="tt-bar">${cells}</span>`;
      }).join('') + '</div>';
    } else {
      bars = '<div class="tt-unscored">Contribution not yet scored.</div>';
    }
    return `<div class="tt-title">${esc(n.title)}</div>` +
           `<div class="tt-meta">${meta}${pos ? ' · ' + esc(pos) : ''}` +
           `<span class="tt-role">${esc(ROLE_LABELS[n.role] || n.role)}</span></div>` + areasHTML(n, areas) + bars;
  }
  let AREAS_ORDER = ['biosocial', 'criminology', 'responders'];
  function showTip(n, g, credit) {
    tip.innerHTML = tooltipHTML(n, credit, AREAS_ORDER);
    tip.style.setProperty('--node', n.colour);
    tip.hidden = false;
  }
  function placeTipAt(x, y) {
    const pad = 14, vw = window.innerWidth, vh = window.innerHeight;
    const r = tip.getBoundingClientRect();
    let left = x + pad, top = y + pad;
    if (left + r.width > vw - 8) left = x - r.width - pad;
    if (top + r.height > vh - 8) top = y - r.height - pad;
    tip.style.left = Math.max(8, left) + 'px';
    tip.style.top  = Math.max(8, top) + 'px';
  }
  function placeTipByNode(g) {
    const r = g.getBoundingClientRect();
    placeTipAt(r.right, r.top + r.height / 2);
  }
  function hideTip() { tip.hidden = true; }
  let originG = null;   // the origin hex, once drawn; pinned like a node but carries the character sheet
  let originHome = null;   // the layer the origin is drawn in; it is lifted to the top layer while pinned
  let nodesLayer = null;   // the <g> the nodes live in; a pinned node is lifted out of it (see gTop) and returned here
  let keepPanel = false;   // set while walking a lineage link: unpin the node but leave the drawer open
  // drop a node back into the nodes layer, under the welds and labels
  const REDUCED = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function settle(g) {
    g.classList.remove('unflipping');
    if (nodesLayer && g.parentNode !== nodesLayer && !g.classList.contains('pinned')) nodesLayer.appendChild(g);
  }
  function unpin() {
    if (pinned) {
      const g = pinned;
      g.classList.remove('pinned', 'lit', 'flipping');
      // flip back (the reverse of the select turn), staying in the top layer until the shrink ends
      if (REDUCED) settle(g);
      else {
        g.classList.add('unflipping');
        let done = false; const finish = () => { if (!done) { done = true; settle(g); } };
        g.addEventListener('animationend', finish, { once: true });
        setTimeout(finish, 700);   // belt and braces: animationend can be swallowed if the tab is hidden
      }
      const id = g.dataset.id; pinned = null; if (window._stLineage) window._stLineage(id, false);
    }
    if (originG && originG.classList.contains('pinned')) {
      const o = originG;
      o.classList.remove('pinned', 'lit', 'flipping');
      const home = () => { o.classList.remove('unflipping'); if (originHome && o.parentNode !== originHome && !o.classList.contains('pinned')) originHome.appendChild(o); };
      if (REDUCED) home();
      else {
        o.classList.add('unflipping');
        let done = false; const finish = () => { if (!done) { done = true; home(); } };
        o.addEventListener('animationend', finish, { once: true });
        setTimeout(finish, 700);
      }
    }
    tip.hidden = true;
    if (!keepPanel) closePanel();
  }

  // --- detail panel ------------------------------------------------------------------------
  const panel = document.getElementById('skilltree-panel');
  const panelBody = panel ? panel.querySelector('.sp-body') : null;
  const EFFORT_LABELS = { 1: 'light', 2: 'modest', 3: 'substantial', 4: 'heavy', 5: 'consuming' };
  function ordinal(k) { const s = ['th', 'st', 'nd', 'rd'], v = k % 100; return k + (s[(v - 20) % 10] || s[v] || s[0]); }
  let EDGES = [], NODE_BY_ID = {}, nodeToggles = {};   // filled in draw(); lineage links in the panel read them
  let IMPACT = null;   // tree.meta.impact: tier cutoffs, label and the one-line definition the panel prints
  const fmtJIF = v => (v == null ? '' : Number(v).toFixed(1));
  const pipsHTML = k => k > 0 ? `<span class="pips" aria-hidden="true">${'\u25CF'.repeat(k)}</span>` : '';
  // achievements (2026-09-20): tree.meta.achievements {label, page, total}; per node n.achievements {n, best, items};
  // career-level ones ride on tree.meta.origin.achievements. All of it comes from data/achievements_log.yml via R.
  let ACH = null, ORIGIN_ACH = null;
  const roman = k => { const t = [[1000,'M'],[900,'CM'],[500,'D'],[400,'CD'],[100,'C'],[90,'XC'],[50,'L'],[40,'XL'],[10,'X'],[9,'IX'],[5,'V'],[4,'IV'],[1,'I']];
    let out = ''; for (const [v, r] of t) while (k >= v) { out += r; k -= v; } return out || ''; };
  const achPlural = k => `${k} achievement${k === 1 ? '' : 's'}`;
  // the Achievements section of the panel (article) or sheet (origin): one row per entry, tier chip then title,
  // each a link to its system message on the achievements page
  function achRows(a) {
    if (!a || !a.items || !a.items.length) return '';
    const page = (ACH && ACH.page) || 'achievements.html';
    return a.items.map(it =>
      `<a class="sp-ach" href="${esc(page)}#${encodeURIComponent(it.key)}"${it.tier ? ` data-tier="${esc(it.tier)}"` : ''}>` +
      `<span class="sp-ach-tier">${esc(it.tier || 'none')}</span><span class="sp-ach-title">${esc(it.title)}</span></a>`).join('');
  }
  function achHTML(a, heading) {
    if (!a || !a.n) return '';
    return `<div class="sp-h">${esc(heading || 'Achievements')} <span class="sp-h-n">${esc(roman(a.n))}</span></div>` + achRows(a);
  }
  // Venue block: the impact factor the venue carried in the JCR year before the article appeared, plus
  // the pips it earns and, once per panel, what the pips mean. Shown for every node that has a JIF.
  function venueHTML(n) {
    const im = n.impact; if (!im || im.jif == null) return '';
    const yr = im.nearest ? `JCR ${esc(im.jcr_year)}, nearest to ${esc(im.requested_year)}; no impact factor that year` : `JCR ${esc(im.jcr_year)}`;
    const badge = im.tier > 0 && IMPACT ? `<span class="sp-venue-tier">${pipsHTML(im.tier)} ${esc(IMPACT.label)}</span>` : '';
    return `<div class="sp-venue"><span class="sp-venue-jif">Impact factor ${esc(fmtJIF(im.jif))}</span>` +
           `<span class="sp-venue-yr">${yr}</span>${badge}</div>` +
           (IMPACT && IMPACT.note ? `<p class="sp-venue-note">${esc(IMPACT.note)} ${esc(IMPACT.source || '')}.</p>` : '');
  }
  function kinHTML(n) {
    const row = id => { const k = NODE_BY_ID[id]; return k
      ? `<button type="button" class="sp-kin" data-id="${esc(k.id)}" style="--kin:${esc(k.colour)}"><span class="yr">${esc(k.year)}</span>${esc(k.title)}</button>` : ''; };
    const parents  = EDGES.filter(e => e.to === n.id).map(e => row(e.from)).join('');
    const children = EDGES.filter(e => e.from === n.id).map(e => row(e.to)).join('');
    if (!parents && !children) return '';
    return `<div class="sp-h">Lineage</div>` +
           (parents  ? `<div class="sp-kin-lab">Builds on</div>${parents}` : '') +
           (children ? `<div class="sp-kin-lab">Built on by</div>${children}` : '');
  }
  function panelHTML(n, credit, areas) {
    const status = STATUS_LABELS[n.status] || '';
    const meta = [n.year, n.venue, n.citation && !/in press|online first/i.test(n.citation) ? n.citation : '', status].filter(Boolean).join(' · ');
    let authors = '';
    if (n.author_position && n.authors_n) authors = `${ordinal(n.author_position)} of ${n.authors_n} authors`;
    else if (n.author_position) authors = `${ordinal(n.author_position)} author on a large team`;
    const areaDots = '<div class="sp-areas">' + areas.map(k => {
      const v = (n.areas && n.areas[k]) || 0;
      return `<span><span class="lab">${esc(AREA_LABELS[k] || k)}</span>${[1, 2, 3].map(i => `<i class="${i <= v ? 'on' : ''}"></i>`).join('')}</span>`;
    }).join('') + '</div>';
    const blurb = n.status === 'preprint' ? '' :                                   // preprints carry no blurb by design
                  n.blurb ? `<p class="sp-blurb">${esc(n.blurb)}</p>` : `<p class="sp-blurb pending">Description to come.</p>`;
    let contrib;
    if (n.scored) {
      contrib = '<div class="sp-grid">' + credit.map(k => {
        const v = n.contribution[k] || 0;
        return `<span class="lab">${esc(CREDIT_LABELS[k] || k)}</span><span class="bar">${[1, 2, 3].map(i => `<span class="${i <= v ? 'on' : ''}"></span>`).join('')}</span><span class="num">${v}/3</span>`;
      }).join('') + '</div>';
    } else contrib = '<p class="sp-unscored">Contribution not yet scored.</p>';
    let effort;
    if (n.effort) {
      effort = `<div class="sp-effort"><span class="blocks">${[1, 2, 3, 4, 5].map(i => `<span class="${i <= n.effort ? 'on' : ''}"></span>`).join('')}</span><span class="lab">${esc(EFFORT_LABELS[n.effort] || n.effort)}</span></div>` +
               (n.effort_note ? `<p class="sp-note">${esc(n.effort_note)}</p>` : '');
    } else effort = '<p class="sp-unscored">Effort not yet rated.</p>';
    const link = n.link
      ? `<a class="sp-link" href="${esc(n.link)}" target="_blank" rel="noopener">${n.doi ? 'Read the article' : 'Open the article'} &rarr;</a>`
      : `<span class="sp-nolink">${n.status === 'in_press' ? 'In press — link to come.' : 'No public link yet.'}</span>`;
    return `<div class="sp-eyebrow">${esc(n.year)} · ${esc(ROLE_LABELS[n.role] || n.role)}</div>` +
           `<h2 class="sp-title">${esc(n.title)}</h2>` +
           `<div class="sp-meta">${esc(meta)}</div>` +
           venueHTML(n) +
           (authors ? `<div class="sp-authors">${esc(authors)}</div>` : '') +
           blurb + areaDots + kinHTML(n) + achHTML(n.achievements) +
           `<div class="sp-h">What I did</div>` + contrib +
           `<div class="sp-h">Effort</div>` + effort + link;
  }
  // --- the origin: Peter's character sheet (easter egg; also reachable as #me) ---------------------
  // Edit the lines here, not in the YAML: this is not an article and never goes through the generator.
  const SHEET = {
    vitals: [
      ['Class',          'None.', 'Ba dum tss.'],
      ['Race',           'Homeschooled', ''],
      ['Specialization', 'None / too many', 'Depends who is asking.'],
      ['Academic pedigree', 'Confused', 'Mixed training. See the three axes.'],
      ['Armor',          'Black belt', 'Not armor, as has been explained to him.'],
      ['Familiars',      'The dogs', 'Neither has read the methods section.']
    ],
    stats: [
      ['Strength',     2, 'grapples'],
      ['Dexterity',    1, 'typing, mostly'],
      ['Constitution', 3, 'survived a postdoc'],
      ['Intelligence', 2, 'has read the appendix'],
      ['Wisdom',       1, 'still runs the fourth robustness check'],
      ['Charisma',     2, 'the dogs like him']
    ],
    xp: 'XP to level 3: \u221e. Not on the tenure track.'
  };
  function sheetHTML() {
    const vitals = '<dl class="sp-sheet">' + SHEET.vitals.map(([k, v, a]) =>
      `<dt>${esc(k)}</dt><dd>${esc(v)}${a ? `<span class="aside">${esc(a)}</span>` : ''}</dd>`).join('') + '</dl>';
    const stats = '<div class="sp-grid sp-stats">' + SHEET.stats.map(([k, v, why]) =>
      `<span class="lab">${esc(k)}</span><span class="bar">${[1, 2, 3].map(i => `<span class="${i <= v ? 'on' : ''}"></span>`).join('')}</span><span class="num">${v}/3</span>` +
      `<span class="why">${esc(why)}</span>`).join('') + '</div>';
    return `<div class="sp-eyebrow">Character sheet · unlocked</div>` +
           `<h2 class="sp-title">Peter T. Tanksley</h2>` +
           `<div class="sp-meta">Research Scientist · Level 2</div>` +
           `<div class="sp-h">Vitals</div>` + vitals +
           `<div class="sp-h">Abilities</div>` + stats +
           achHTML(ORIGIN_ACH) +
           `<p class="sp-note sp-xp">${esc(SHEET.xp)}</p>` +
           `<a class="sp-link" href="1_about/about.html">Full backstory &rarr;</a>`;
  }
  function openSheet(g) {
    if (!panel) return;
    panelBody.innerHTML = sheetHTML();
    panel.style.setProperty('--node', '#D9A441');   // gold, matching .origin-ring
    panel.hidden = false;
    fitAroundPanel(true);
    lastFocus = g;
    if (history.replaceState) history.replaceState(null, '', '#me');
  }
  // Make room for the drawer: pad the tree's container by exactly the overlap between its right edge
  // and the panel's left edge, so the SVG rescales to the space left and nothing sits under the panel.
  // No-op when the panel is a bottom sheet (narrow viewports) or already clear of the tree.
  const wrap = root.closest('.skilltree-wrap');
  function fitAroundPanel(open) {
    if (!wrap || !panel) return;
    let pad = 0;
    if (open && window.matchMedia('(min-width: 721px)').matches) {
      const panelLeft = window.innerWidth - Math.min(400, window.innerWidth * 0.92);
      pad = Math.max(0, Math.round(wrap.getBoundingClientRect().right - panelLeft) + 16);
    }
    wrap.style.paddingRight = pad ? pad + 'px' : '';
  }
  window.addEventListener('resize', () => { if (panel && !panel.hidden) fitAroundPanel(true); });
  let lastFocus = null;
  function openPanel(n, g, credit) {
    if (!panel) return;
    panelBody.innerHTML = panelHTML(n, credit, AREAS_ORDER);
    // lineage rows open the connected article in place (same as clicking its hex)
    // Walking a lineage link is staged so the eye can follow: the text fades out and the current hex
    // eases back to size; then the linked hex flips and its text fades in. The drawer stays open.
    panelBody.querySelectorAll('.sp-kin').forEach(b => b.addEventListener('click', e => {
      e.stopPropagation();
      const t = nodeToggles[b.dataset.id]; if (!t) return;
      const fake = { preventDefault() {}, stopPropagation() {} };
      const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      keepPanel = true;
      panelBody.classList.add('sp-fade');
      unpin();                                     // old hex eases back (transition on .node), panel stays
      const kg = root.querySelector(`.node[data-id="${b.dataset.id}"]`);
      if (kg) kg.scrollIntoView({ block: 'center', behavior: reduce ? 'auto' : 'smooth' });
      setTimeout(() => {
        t(fake);                                   // flips the linked hex and rewrites the panel body
        panelBody.classList.remove('sp-fade');     // new text fades in
        keepPanel = false;
      }, reduce ? 0 : 420);
    }));
    panel.style.setProperty('--node', n.colour);
    panel.hidden = false;
    fitAroundPanel(true);
    lastFocus = g;
    if (history.replaceState) history.replaceState(null, '', '#' + encodeURIComponent(n.id));
  }
  function closePanel() {
    if (!panel || panel.hidden) return;
    panel.hidden = true;
    fitAroundPanel(false);
    if (history.replaceState && location.hash) history.replaceState(null, '', location.pathname + location.search);
    if (lastFocus && document.activeElement === panel.querySelector('.sp-close')) lastFocus.focus();
  }

  // --- draw ----------------------------------------------------------------------------------
  function draw(tree) {
    const m = tree.meta;
    EDGES = tree.edges || [];
    NODE_BY_ID = Object.fromEntries((tree.nodes || []).map(n => [n.id, n]));
    const credit = m.credit || Object.keys(CREDIT_LABELS);
    if (m.areas) AREAS_ORDER = m.areas;
    IMPACT = m.impact || null;
    ACH = m.achievements || null;
    ORIGIN_ACH = (m.origin && m.origin.achievements) || null;
    // roman numeral on the lower-left edge, the mirror of the pips' place on the upper-right: how many
    // achievements this hex has earned. Point-up hex: that edge runs from the bottom vertex up-left at 30
    // degrees; the numeral sits inside it, rotated to read along the edge. Gold with an ink stroke like the pips.
    const drawNumeral = (parent, cx, cy, w, h, k) => {
      if (!k) return;
      const ex = -Math.cos(Math.PI / 6), ey = -Math.sin(Math.PI / 6);      // along the edge, bottom vertex -> lower-left vertex
      const nx = -ey, ny = ex;                                             // inward normal of that edge (up-right)
      const side = h / 2;                                                  // edge length of a point-up hex = h/2
      const tx = cx + ex * side * 0.5 + nx * w * 0.13, ty = cy + h / 2 + ey * side * 0.5 + ny * w * 0.13;
      const t = svgEl('text', { class: 'hex-num', x: tx, y: ty, 'font-size': w * 0.15, transform: `rotate(30 ${tx} ${ty})`, 'aria-hidden': 'true' }, parent);
      t.textContent = roman(k);
    };
    const svg = svgEl('svg', {
      viewBox: `0 0 ${m.width} ${m.height}`, role: 'group',
      'aria-label': 'Publications on concentric rings by year, placed by direction between three research areas: biosocial, criminology and first-responder occupational'
    }, root);

    // the field: year rings (hexagon guides), three area axes, and Peter at the origin
    const gT = svgEl('g', { class: 'field' }, svg);
    // a soft glow behind the origin so the eye starts at the centre
    const defs = svgEl('defs', {}, svg);
    const grad = svgEl('radialGradient', { id: 'st-glow' }, defs);
    svgEl('stop', { offset: '0%', 'stop-color': '#FBFAF7', 'stop-opacity': '0.10' }, grad);
    svgEl('stop', { offset: '55%', 'stop-color': '#FBFAF7', 'stop-opacity': '0.025' }, grad);
    svgEl('stop', { offset: '100%', 'stop-color': '#FBFAF7', 'stop-opacity': '0' }, grad);
    if (m.origin) svgEl('circle', { cx: m.origin.x, cy: m.origin.y, r: Math.min(m.width, m.height) * 0.42, fill: 'url(#st-glow)' }, gT);
    // a faint wash of each area's colour along its axis, under the guides: a wide line painted with a
    // gradient that runs perpendicular to the axis, colour at the centre fading out at both edges
    const GLOW_W = m.hex_w * 3.2;
    m.axes.forEach((a, i) => {
      const dx = a.x2 - a.x1, dy = a.y2 - a.y1, len = Math.hypot(dx, dy) || 1;
      const nx = -dy / len, ny = dx / len, mx = (a.x1 + a.x2) / 2, my = (a.y1 + a.y2) / 2;
      const g = svgEl('linearGradient', { id: `st-axis-glow-${i}`, gradientUnits: 'userSpaceOnUse',
        x1: mx - nx * GLOW_W / 2, y1: my - ny * GLOW_W / 2, x2: mx + nx * GLOW_W / 2, y2: my + ny * GLOW_W / 2 }, defs);
      svgEl('stop', { offset: '0%',   'stop-color': a.colour, 'stop-opacity': '0' }, g);
      svgEl('stop', { offset: '50%',  'stop-color': a.colour, 'stop-opacity': '0.13' }, g);
      svgEl('stop', { offset: '100%', 'stop-color': a.colour, 'stop-opacity': '0' }, g);
      // and a mask so the wash also fades along its length: full near the origin, gone by the label
      const fade = svgEl('linearGradient', { id: `st-axis-fade-${i}`, gradientUnits: 'userSpaceOnUse', x1: a.x1, y1: a.y1, x2: a.x2, y2: a.y2 }, defs);
      svgEl('stop', { offset: '0%',   'stop-color': '#fff', 'stop-opacity': '1' }, fade);
      svgEl('stop', { offset: '55%',  'stop-color': '#fff', 'stop-opacity': '0.8' }, fade);
      svgEl('stop', { offset: '100%', 'stop-color': '#fff', 'stop-opacity': '0' }, fade);
      const mask = svgEl('mask', { id: `st-axis-mask-${i}`, maskUnits: 'userSpaceOnUse', x: 0, y: 0, width: m.width, height: m.height }, defs);
      svgEl('rect', { x: 0, y: 0, width: m.width, height: m.height, fill: `url(#st-axis-fade-${i})` }, mask);
      svgEl('line', { class: 'axis-glow', x1: a.x1, y1: a.y1, x2: a.x2, y2: a.y2, mask: `url(#st-axis-mask-${i})`,
        style: `stroke:url(#st-axis-glow-${i})`, 'stroke-width': GLOW_W, 'stroke-linecap': 'round' }, gT);   // round: the three meet in a disc at the origin, not a triangle; the fade mask hides the far cap
    });
    m.rings.forEach(rg => svgEl('path', { class: 'ring-guide', d: rg.path }, gT));
    m.axes.forEach(a => svgEl('line', { class: 'axis', x1: a.x1, y1: a.y1, x2: a.x2, y2: a.y2, style: `stroke:${a.colour}` }, gT));
    let toggleOrigin = null;
    if (m.origin) {
      const k = m.origin.scale || 1, ow = m.hex_w * k, oh = m.hex_h * k;
      originG = svgEl('g', { class: 'origin-node', tabindex: '0', role: 'button',
        'aria-label': 'Peter Tanksley, at the origin. Opens a character sheet.' + (ORIGIN_ACH && ORIGIN_ACH.n ? ` ${achPlural(ORIGIN_ACH.n)}.` : '') }, gT);
      originHome = gT;
      svgEl('image', {
        class: 'origin', href: m.origin.sticker_src, x: m.origin.x - ow / 2, y: m.origin.y - oh / 2,
        width: ow, height: oh, preserveAspectRatio: 'xMidYMid meet', 'aria-hidden': 'true'
      }, originG);
      svgEl('path', { class: 'origin-ring', d: hexPath(m.origin.x, m.origin.y, ow * 1.02, oh * 1.02) }, originG);
      drawNumeral(originG, m.origin.x, m.origin.y, ow, oh, ORIGIN_ACH ? ORIGIN_ACH.n : 0);   // career-level achievements
      const originTip = () => {
        tip.innerHTML = '<div class="tt-title">Peter T. Tanksley</div><div class="tt-meta">Research Scientist · Level 2 · click to inspect</div>';
        tip.style.setProperty('--node', '#D9A441'); tip.hidden = false;   // gold, matching .origin-ring
      };
      originG.addEventListener('mouseenter', e => { originTip(); placeTipAt(e.clientX, e.clientY); });
      originG.addEventListener('mousemove',  e => placeTipAt(e.clientX, e.clientY));
      originG.addEventListener('mouseleave', hideTip);
      originG.addEventListener('focus', () => { originTip(); placeTipByNode(originG); });
      originG.addEventListener('blur', hideTip);
      toggleOrigin = e => {
        e.preventDefault(); e.stopPropagation();
        if (originG.classList.contains('pinned')) { unpin(); return; }
        unpin();
        originG.classList.remove('unflipping');   // re-selected mid-shrink: cancel the return trip
        gTop.appendChild(originG);   // lift above the rings, year labels and neighbours while enlarged; unpin() returns it to gT
        originG.classList.add('pinned', 'flipping', 'lit');
        tip.hidden = true;
        openSheet(originG);
      };
      originG.addEventListener('click', toggleOrigin);
      originG.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') toggleOrigin(e); });
    }

    // lineage edges (builds_on): parent → child beneath the nodes, a gradient from the parent's colour
    // to the child's, slightly bowed toward the origin so they read as branches rather than spokes
    const gE = svgEl('g', { class: 'edges' }, svg);              // long edges: beneath the nodes
    const gBridge = svgEl('g', { class: 'edges bridges' });        // neighbour welds: appended above the nodes later
    const edgesByNode = {};
    (tree.edges || []).forEach((e, i) => {
      const gid = `st-edge-${i}`;
      const lg = svgEl('linearGradient', { id: gid, gradientUnits: 'userSpaceOnUse', x1: e.x1, y1: e.y1, x2: e.x2, y2: e.y2 }, defs);
      svgEl('stop', { offset: '0%', 'stop-color': e.from_colour }, lg);
      svgEl('stop', { offset: '100%', 'stop-color': e.to_colour }, lg);
      let path, tip;
      if (e.adjacent) {
        // weld across the shared border, straight and thick, above the tiles
        path = svgEl('path', { class: 'edge bridge', d: `M${e.x1},${e.y1} L${e.x2},${e.y2}`, style: `stroke:url(#${gid})`, 'data-from': e.from, 'data-to': e.to }, gBridge);
      } else {
        // control point: the midpoint nudged toward the origin by a fraction of the edge length
        const mx = (e.x1 + e.x2) / 2, my = (e.y1 + e.y2) / 2;
        const ox = m.origin ? m.origin.x : m.width / 2, oy = m.origin ? m.origin.y : m.height / 2;
        const len = Math.hypot(e.x2 - e.x1, e.y2 - e.y1), dO = Math.hypot(ox - mx, oy - my) || 1;
        const bow = Math.min(len * 0.18, 40);
        const cx = mx + (ox - mx) / dO * bow, cy = my + (oy - my) / dO * bow;
        path = svgEl('path', { class: 'edge', d: `M${e.x1},${e.y1} Q${cx},${cy} ${e.x2},${e.y2}`, style: `stroke:url(#${gid})`, 'data-from': e.from, 'data-to': e.to }, gE);
        // a small dot at the child end marks direction without an arrowhead's clutter
        tip = svgEl('circle', { class: 'edge-tip', cx: e.x2, cy: e.y2, r: 5, style: `fill:${e.to_colour}` }, gE);
      }
      const parts = tip ? [path, tip] : [path];
      (edgesByNode[e.from] = edgesByNode[e.from] || []).push(...parts);
      (edgesByNode[e.to]   = edgesByNode[e.to]   || []).push(...parts);
    });
    const setLineage = window._stLineage = (id, on) => {
      const mine = edgesByNode[id] || [];
      if (!mine.length) { svg.classList.remove('has-hot'); return; }
      svg.classList.toggle('has-hot', on);
      svg.querySelectorAll('.edge.hot, .edge-tip.hot').forEach(el => el.classList.remove('hot'));
      if (on) mine.forEach(el => el.classList.add('hot'));
    };

    // nodes
    const gN = svgEl('g', { class: 'nodes' }, svg);
    nodesLayer = gN;
    nodeToggles = {};   // module-level so the panel's lineage rows can open a node
    tree.nodes.forEach(n => {
      const cls = `node role-${n.role} status-${n.status}` + (n.featured ? '' : ' muted');
      const label = [n.title, n.year, n.venue].filter(Boolean).join(', ') +
                    `. ${ROLE_LABELS[n.role] || n.role}. ${areasText(n, m.areas)}.` +
                    (n.scored ? '' : ' Contribution not yet scored.') +
                    (n.impact && n.impact.tier > 0 && IMPACT ? ` ${IMPACT.label}, impact factor ${fmtJIF(n.impact.jif)}.` : '') +
                    (n.achievements && n.achievements.n ? ` ${achPlural(n.achievements.n)}.` : '');
      const g = svgEl('g', {
        class: cls, tabindex: 0, role: 'button', 'data-id': n.id,
        'aria-label': label, style: `--node: ${n.colour}`
      }, gN);
      svgEl('image', {
        href: n.sticker_src, x: n.x - m.hex_w / 2, y: n.y - m.hex_h / 2,
        width: m.hex_w, height: m.hex_h, preserveAspectRatio: 'xMidYMid meet'
      }, g);
      svgEl('path', { class: 'hex-shade', d: hexPath(n.x, n.y, m.hex_w * 0.99, m.hex_h * 0.99) }, g);
      svgEl('path', { class: 'hex-ring', d: hexPath(n.x, n.y, m.hex_w * 0.96, m.hex_h * 0.96) }, g);
      // impact pips (2026-09-19): 1-3 gold dots running down the hex's upper-right edge from the top vertex,
      // drawn after the shade so they stay lit when the tile is dimmed. No transform, no filter; they ride the
      // tile's scale when it is pinned. Point-up hex: the edge runs at 30 degrees below horizontal.
      if (n.impact && n.impact.tier > 0) {
        const k = n.impact.tier, r = m.hex_w * 0.05, pitch = r * 2.5;
        const ex = Math.cos(Math.PI / 6), ey = Math.sin(Math.PI / 6);        // along the edge, top vertex -> upper-right vertex
        const nx = -ey, ny = ex;                                              // inward normal of that edge
        const sx = n.x + ex * r * 3.2 + nx * r * 2.2, sy = n.y - m.hex_h / 2 + ey * r * 3.2 + ny * r * 2.2;   // first pip
        const gp = svgEl('g', { class: 'hex-pips', 'data-tier': k }, g);
        for (let i = 0; i < k; i++) svgEl('circle', { cx: sx + ex * pitch * i, cy: sy + ey * pitch * i, r }, gp);
      }
      drawNumeral(g, n.x, n.y, m.hex_w, m.hex_h, n.achievements ? n.achievements.n : 0);

      // hover / focus: tooltip only. Nothing moves, so the pointer target never shifts underneath.
      g.addEventListener('mouseenter', e => { showTip(n, g, credit); placeTipAt(e.clientX, e.clientY); setLineage(n.id, true); });
      g.addEventListener('mousemove',  e => placeTipAt(e.clientX, e.clientY));
      g.addEventListener('mouseleave', () => { hideTip(); if (pinned) setLineage(pinned.dataset.id, true); else setLineage(n.id, false); });
      g.addEventListener('focus', () => { showTip(n, g, credit); placeTipByNode(g); setLineage(n.id, true); });
      g.addEventListener('blur', () => { hideTip(); if (pinned) setLineage(pinned.dataset.id, true); else setLineage(n.id, false); });
      // click / Enter / Space: flip the hex face-up and pin it; again (or Esc, or elsewhere) turns it back
      const toggle = e => {
        e.preventDefault(); e.stopPropagation();
        if (pinned === g) { unpin(); return; }
        unpin(); pinned = g;
        g.classList.remove('unflipping');   // re-selected mid-shrink: cancel the return trip
        gTop.appendChild(g);   // lift above neighbours, welds and labels while enlarged; unpin() returns it to gN
        g.classList.add('pinned', 'flipping', 'lit');
        setLineage(n.id, true);
        tip.hidden = true;                                                  // the panel carries the detail now
        openPanel(n, g, credit);
      };
      nodeToggles[n.id] = toggle;
      g.addEventListener('click', toggle);
      g.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') toggle(e); });
    });

    svg.appendChild(gBridge);   // welds above the tiles

    // labels last, above everything: axis names past the outer ring, years on each ring's top edge
    const gL = svgEl('g', { class: 'labels' }, svg);
    // ...except the one pinned node, which is lifted into this top layer so its enlarged tile is not
    // crossed by welds or year labels
    const gTop = svgEl('g', { class: 'nodes nodes-top' }, svg);
    m.axes.forEach(a => {
      const t = svgEl('text', { class: 'axis-label', x: a.label_x, y: a.label_y, 'text-anchor': a.anchor, style: `fill:${a.colour}` }, gL);
      t.textContent = a.label;
    });
    m.rings.forEach(rg => {
      const t = svgEl('text', { class: 'year-label' + (rg.label_over_hex ? ' over-hex' : ''), x: rg.label_x, y: rg.label_y }, gL);
      t.textContent = rg.year;
    });

    // legend, built from the same JSON as the drawing so nothing drifts: area colours as filled hexes,
    // roles and status as hex outlines drawn with the same stroke weights the nodes use
    const leg = document.getElementById('skilltree-legend');
    if (leg) {
      const icon = (opts) => `<svg class="lg-hex" viewBox="0 0 20 23" aria-hidden="true"><path d="${hexPath(10, 11.5, opts.w || 16, opts.h || 18.5)}" ` +
        `fill="${opts.fill || 'none'}" stroke="${opts.stroke || 'currentColor'}" stroke-width="${opts.sw || 1.5}" ${opts.dash ? 'stroke-dasharray="3 2.2"' : ''} stroke-linejoin="round"/></svg>`;
      const item = (html, text) => `<span class="lg-item">${html}${esc(text)}</span>`;
      leg.innerHTML =
        `<div class="lg-row">${item(icon({ sw: 3 }), 'Lead author')}${item(icon({ sw: 1 }), 'Contributing author')}` +
        `${item(icon({ sw: 1.5, dash: true }), 'In press or preprint')}` +
        // one gold pip at legend size (pips drawn inside a legend hex are too small to read)
        (IMPACT ? item(`<svg class="lg-hex lg-pips" viewBox="0 0 20 23" aria-hidden="true"><circle cx="10" cy="11.5" r="4.2"/></svg>`, IMPACT.label) : '') +
        // the numeral at legend size, linking to the page that explains it
        (ACH && ACH.total ? `<a class="lg-item lg-ach" href="${esc(ACH.page || 'achievements.html')}"><span class="lg-num" aria-hidden="true">III</span>${esc(ACH.label || 'Achievements earned')}</a>` : '') +
        `${item('<svg class="lg-hex" viewBox="0 0 20 23" aria-hidden="true"><path d="M2,19 Q6,9 18,4" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/><circle cx="18" cy="4" r="2.4" fill="currentColor"/></svg>', 'Builds on an earlier article')}</div>`;
    }

    document.addEventListener('keydown', e => { if (e.key === 'Escape') unpin(); });
    document.addEventListener('click', e => { if (!e.target.closest('.node') && !e.target.closest('.origin-node') && !e.target.closest('.skilltree-panel')) unpin(); });
    if (panel) panel.querySelector('.sp-close').addEventListener('click', e => { e.stopPropagation(); unpin(); });

    // deep link: /skilltree.html#<id> opens that article, on load and whenever the hash changes
    const openFromHash = () => {
      const want = decodeURIComponent((location.hash || '').slice(1));
      if (want === 'me' && toggleOrigin) {
        if (!originG.classList.contains('pinned')) { toggleOrigin({ preventDefault() {}, stopPropagation() {} }); originG.scrollIntoView({ block: 'center' }); }
        return;
      }
      if (!want || !nodeToggles[want]) return;
      const g = gN.querySelector(`[data-id="${want}"]`);
      if (pinned === g) return;
      nodeToggles[want]({ preventDefault() {}, stopPropagation() {} });
      if (g) g.scrollIntoView({ block: 'center' });
    };
    openFromHash();
    window.addEventListener('hashchange', openFromHash);
  }

  // citation stats card in the tree box's empty upper-right corner. Optional: the tree draws without it.
  const statsSrc = root.dataset.stats || 'www/scholar.json';
  const fmtN = n => (n == null ? '\u2013' : Number(n).toLocaleString('en-US'));
  const fmtDate = s => { const d = new Date(String(s).replace(' ', 'T')); return isNaN(d) ? String(s) : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }); };
  let STATS_JSON = null, TREE_DRAWN = false;
  const maybeStats = () => { if (STATS_JSON && TREE_DRAWN) { drawStats(STATS_JSON); STATS_JSON = null; } };
  function drawStats(j) {
    const sc = j && j.scholar; if (!sc) return;
    const oa = j.openalex || {};
    const tip = (five, o) => `Since 2021: ${fmtN(five)} \u00b7 OpenAlex: ${fmtN(o)}`;
    const url = `https://scholar.google.com/citations?user=${encodeURIComponent((j.meta && j.meta.scholar_id) || '')}&hl=en`;
    const card = document.createElement('div'); card.className = 'st-stats';
    card.innerHTML =
      `<div class="ss-eyebrow">Google Scholar</div>` +
      `<div class="ss-row">` +
        `<div class="ss-stat" title="${esc(tip(sc.citations_5y, oa.citations))}"><span class="ss-n">${fmtN(sc.citations)}</span><span class="ss-l">citations</span></div>` +
        `<div class="ss-stat" title="${esc(tip(sc.h_index_5y, oa.h_index))}"><span class="ss-n">${fmtN(sc.h_index)}</span><span class="ss-l">h-index</span></div>` +
        `<div class="ss-stat" title="${esc(tip(sc.i10_5y, oa.i10))}"><span class="ss-n">${fmtN(sc.i10)}</span><span class="ss-l">i10</span></div>` +
        (ACH && ACH.total ? `<a class="ss-stat ss-ach" href="${esc(ACH.page || 'achievements.html')}" title="${esc(achPlural(ACH.total))}${ACH.latest ? ', latest ' + esc(fmtDate(ACH.latest)) : ''}"><span class="ss-n">${esc(roman(ACH.total))}</span><span class="ss-l">achievements</span></a>` : '') +
      `</div>` +
      `<div class="ss-foot">as of ${esc(fmtDate(j.meta && j.meta.fetched))} \u00b7 <a href="${url}" target="_blank" rel="noopener">profile \u2192</a></div>`;
    root.appendChild(card);
  }
  fetch(statsSrc, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).then(j => { if (j) { STATS_JSON = j; maybeStats(); } })
    .catch(err => console.info('skilltree: no citation stats (' + err.message + ')'));

  const src = root.dataset.src || 'www/tree.json';
  fetch(src, { cache: 'no-store' })
    .then(r => { if (!r.ok) throw new Error(`${src}: HTTP ${r.status}`); return r.json(); })
    .then(t => { draw(t); TREE_DRAWN = true; maybeStats(); })
    .catch(err => {
      root.textContent = 'Could not load the tree data (run R/build_tree.R, then reload).';
      console.error('skilltree:', err);
    });
})();
