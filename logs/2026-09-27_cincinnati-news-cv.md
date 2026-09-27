# 2026-09-27 — Cincinnati trip: CV invited talk, news item with first photo

**CV.** New 2026 invited talk from the Tristate FACE Team flyer
(`Non_work_work/cincinnati_2026/docs/admin/uc_face_team_meeting_flyer.jpeg`): "Leading causes of death among
first responders," Tristate FACE (Firefighters Attacking the Cancer Epidemic) Team Meeting, College of Education,
Criminal Justice, and Human Services, University of Cincinnati. Flyer billed J.C. Barnes and Peter as featured
speakers; the CV's talk format carries no co-presenters, so that is not recorded there. The grad-student career
talk given on the same trip ("Paths Nobody Told You About") was not added; Peter asked for the flyer talk only.
The pre-existing 2026 entry "Go analog, baby!" (UC Biosocial Criminology doctoral course) was left as found.

**News.** Entry `cincinnati-face-2026`, dated 2026-09-22 (the delivery date Peter reported on 09-23; the flyer
says Wed 09-23). First news item to carry a photo: `image` + `image-alt` fields added to `news.yml`, rendered by
`news-listing.ejs` on the news page only (homepage list stays text), styled `.news-photo` in `theme.scss`
(30rem max, 4px radius). Photo: `IMG_1109.HEIC` from Downloads → `sips` → `www/uc_2026.jpg`, 1200 px, 306 KB.
Original HEIC left in Downloads.

**Gotcha.** An EJS conditional on its own line renders as an empty line when false, and a blank line ends
pandoc's raw-HTML block: every item after the first came back `<p>`-wrapped and collapsed into the 7.5em date
column. Keep optional template fragments on the same line as a fragment that always renders. Verified by
screenshot at 1100 and 420 px and by `grep -c '<p><span class="when"' docs/news.html` = 0.
