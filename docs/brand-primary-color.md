# Primary brand color (Community)

`BRAND_PRIMARY_COLOR` is an installation-wide accent color available on the
Community edition and on paid editions. It does not require an account feature
flag or a branding subscription.

## Configure

1. Deploy the code and compile the Vite assets using the normal deployment flow.
2. Reconcile new installation settings, preserving existing values:
   ```sh
   bundle exec rails runner 'ConfigLoader.new.process'
   ```
3. Open **Super Admin → Settings → General**
   (`/super_admin/app_config?config=general`).
4. Select **Primary Brand Color**, save, then reload open application pages.

The default is the existing Chatwoot blue, `#2781f6`. Values use six-digit hex
notation (`#RRGGBB`), for example `#29a2a7`. Invalid values are rejected when
saving an installation config. A blank value falls back to the shipped palette.
The setting is editable (`locked: false`) and is absent from the Enterprise
premium installation-config reset list.

The shared Vite entrypoint applies the color on dashboard, authentication, and
Super Admin pages. Existing Tailwind `n-brand`, `n-blue-*`, and legacy `woot-*`
utilities consume the generated tokens, including opacity modifiers. Light and
dark aliases follow the existing theme classes, including components mounted
after initialization. Resetting to `#2781f6` restores the original palettes.

## REA investigation

Reference: `chatwoot_v4.26.5/`, Git SHA
`be2810d69e9add25d72dc1d11e5ee30f6b884691`.

Executed from the local `rea/` directory with REA 6.5.0 and Node 24.19.0:

```sh
node scripts/rea.mjs analyze-javascript-application \
  /home/ubuntu/dev/clone-mega/chatwoot_v4.26.5/public/vite \
  --source-path assets/brandColor-CqzvkRrp.js \
  --format json > /tmp/opencode/brand-primary-color-rea.json
```

- Evidence ID:
  `ev_df7d896cda0332b4372250d787b4d2aaa1473bd571af885f01c8c5922c090b0e`.
- Root artifact SHA-256:
  `16b3790f2f7faf6f003bc2292eaec5c46c39e8f0740844aa2833b1982bf96898`.
- Selected bundle SHA-256:
  `930c07629d3a24c94ff08c1dc6c845614f999f5564b9cc8933122b7f193d0daf`.
- The semantic graph records a `BRAND_PRIMARY_COLOR` property read at line 1,
  columns 1821–1842. Complementary Babel AST formatting shows config resolution,
  palette generation, and CSS custom-property writes. The reference's backend
  also exposes the setting through `DashboardController`.
- Coverage: one selected JavaScript source; 494 inventoried files outside the
  selected scope. This was static inspection; the reference application was not
  executed. REA records the canonical artifact path under
  `/home/ubuntu/dev/sendingtk/`, although the input path uses `clone-mega/`.

The adaptation retains the destination's default palette and uses separate
light/dark aliases rather than copying the reference's same-blue override for
both modes.

## Verification performed

- ESLint using the repository's rules for the two new JavaScript files and
  `theme/colors.js`.
- SCSS compilation, Tailwind utility generation, and JavaScript bundling.
- Chromium checks using the compiled styles and actual shared entrypoint:
  custom colors, Tailwind opacity modifiers, light/dark changes on the root and
  body, components inserted after initialization, invalid values, and reset.
  The default computed colors were compared against the unmodified destination
  in both modes.
- YAML registration and exclusion from the premium reset list.

The temporary verification harness is
`/tmp/opencode/brand-color-validation/verify.mjs`. It tests frontend behavior in
an isolated page, not a running Chatwoot server. Rails request, database save,
and cache invalidation checks could not be executed because Ruby/Bundler were
unavailable in this environment.
