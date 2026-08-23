# Play Store listing package

Everything needed for the Play Console "Store listing" page, generated
from the current app build. Not published anywhere — copy/paste into
Play Console yourself.

## Text (character limits already checked)

- `title.txt` — app title (20/30 chars)
- `short_description.txt` — short description (71/80 chars)
- `full_description.txt` — full description (1070/4000 chars)
- `release_notes.txt` — "What's new" text for this release (365/500 chars)

## Graphics

- `icon_512.png` — 512x512 hi-res icon (Play Console's separate icon
  upload, distinct from the in-app adaptive icon)
- `feature_graphic.png` — 1024x500 feature graphic
- `screenshots/` — phone screenshots captured on a Pixel-class emulator
  (1080x2400): home, vendor catalog, model list, model detail, wiring
  view. Play Console needs at least 2; these 5 cover the main flow.

## Still needed (can't be generated — needs your Play Console account)

- **Privacy policy URL** — https://wiring.scottnation.com/privacy.html is
  the stable one to use (doesn't depend on the GitHub repo/Pages name).
  The GitHub Pages copy also works but its URL changed to
  https://computergeek1507.github.io/xmodel_wiring_viewer/privacy.html
  after the repo rename — only usable once that Pages deploy finishes.
- **App category** — suggest "Tools" or "Lifestyle".
- **Contact email** — your own.
- **Content rating questionnaire** — answer in Play Console (no ads, no
  user-generated content, no data collection → should land on "Everyone").
- **Data safety section** — the app collects no personal data and has no
  analytics/ads SDKs; `web/privacy.html` already documents this in detail
  if you need wording for the form.
- **Signed release AAB** — built at
  `build/app/outputs/bundle/release/app-release.aab` with a real upload
  keystore (see the top-level project README's "Release signing"
  section for where that keystore lives and why it must be backed up).
