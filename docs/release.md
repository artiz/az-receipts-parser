# Releasing to Google Play

The app is on the **internal testing** track, installed and updated through
Play for a handful of named testers. The developer account is an
**organization** account (with a D-U-N-S number), so production needs no
closed test with 12 testers first. Releases are built and uploaded by
GitHub Actions ([below](#releases-from-github-actions)); the local build is
the fallback.

## One-time setup

1. **Developer account.** https://play.google.com/console, organization
   account, 25 USD once. It needs a D-U-N-S number (free from Dun &
   Bradstreet; a new number is visible to Google about a day after it is
   issued, and the console allows only a few lookups, so do not retry
   early). Name and address must match the D&B record exactly. Then:
   identity verification (a few days), developer email and phone, and the
   Android device check in the Play Console app.
2. **Upload key.** On the machine that builds bundles:

   ```bat
   scripts\make_keystore.bat
   ```

   It creates `%USERPROFILE%\az-budget-upload.jks` (outside the repo) and
   writes `app\android\key.properties` (ignored by git). Back up the `.jks`
   and the password: with Play App Signing a lost upload key can be reset
   through Play support, but it costs days.
3. **Create the app** in the console: name `AZ Budget`, default language
   English (German and Russian are added as translations), app (not game),
   free. Free cannot be changed to paid later.

## Build the bundle

```bat
scripts\build_android.bat --bundle
```

Output: `app\build\app\outputs\bundle\release\app-release.aab`. The version
code is the commit count of the branch, so every build from a newer commit is
accepted as an update; the version name (`1.0.0`) comes from `pubspec.yaml`,
bump it there for visible releases. `--no-rust` works as for the APK.

The bundle is arm64 only (the Rust OCR library is built for arm64), which
Play accepts: 64-bit is required, 32-bit is optional. Devices without arm64
(x86 emulators, old 32-bit phones) will not see the app. Native libraries
are 16 KB page-aligned (onnxruntime 1.31.1 ships that way, the Rust library
is linked with `max-page-size=16384`), which Play requires for Android 15+
targets; the App bundle explorer in the console flags it otherwise.

## Console checklist before the first upload

All under **Set up your app** on the dashboard:

- **Privacy policy**: `https://github.com/artiz/az-receipts-parser/blob/master/docs/privacy.md`
  (or a GitHub Pages copy).
- **App access**: all functionality available without special access; add a
  note for reviewers: no account, pick any folder when asked (an empty one
  gets a budget file created), the OpenAI key is optional.
- **Ads**: no. **Content rating**: fill the questionnaire (utility /
  productivity, no user-generated content), expect "Everyone".
- **Target audience**: 16 and over (as submitted). **News app**: no. **COVID-19**: no.
- **Data safety** (as submitted): collects data, encrypted in transit
  (HTTPS), no deletion request (nothing is stored on a server). One data
  type: *Financial info → Other financial info* (the text of an imported
  statement or screenshot sent to OpenAI with the user's own key):
  collected, not shared (the user starts the transfer), processed
  ephemerally, optional, for app functionality. Nothing else: the budget
  file goes to the user's own folder, no analytics, no identifiers.
- **Permissions** in the bundle: internet, notifications, camera (the in-app
  receipt camera). The camera plugin also declares the microphone and legacy
  storage, and the manifest merger adds READ_EXTERNAL_STORAGE as implied by
  the latter. `AndroidManifest.xml` removes all three (`tools:node="remove"`)
  and marks the camera as not required (the phone's camera app is the
  fallback); the release workflow fails if any of them shows up in the
  bundle's manifest (bundletool). Camera frames
  are analysed on the device only, so Data safety does not change.
- **Government apps / Financial features**: the financial features
  declaration applies to loans, banking, crypto and the like; a personal
  budgeting tool declares "none of the above".
- **Store listing**: everything is prepared in [listing/](listing/README.md):
  icon 512×512, feature graphic 1024×500, four phone screenshots and the
  short and full descriptions in English (default), German and Russian.

## Internal testing

1. **Testing → Internal testing → Testers**: create an email list with the
   Google accounts of the testers (up to 100), save, copy the opt-in link.
2. **Create new release**: on the first upload accept Play App Signing (Play
   keeps the app signing key, your `.jks` is the upload key). Upload the
   `.aab`, release name is filled from the version, add short notes, review,
   **Start rollout to Internal testing**.
3. Each tester opens the opt-in link once, taps "Become a tester", then
   installs from the Play Store link on that page. Updates arrive like any
   store update after each new rollout (usually within minutes on the
   internal track; a "Not available" message right after rollout means
   waiting a bit).

**Switching keys.** Android updates an installed app only with a build
signed by the same key. Three keys are in play: the debug key (builds from
before `android\key.properties` existed), the upload key (builds since), and
the Play app signing key (installs from the store). Crossing any of them
fails with

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package dev.artiz.az_budget signatures do not match newer version
```

so uninstall first:

```bat
adb uninstall dev.artiz.az_budget
```

Device data goes with it (folder grant, language, OpenAI key, a queued
booking not yet written); the `Budget <year>.xlsx` in the folder is untouched.
After the new install: choose the folder again, re-enter the key.
`scripts\build_android.bat --install` prints this explanation when it hits
the error. The first build after `make_keystore.bat` is such a switch, and
so is the move to the Play install later. To keep developing beside a Play
install, use a second device.

## Releases from GitHub Actions

`.github/workflows/release.yml` builds the signed bundle on a GitHub runner
(Rust OCR library, models, tests, `flutter build appbundle`) and uploads it
to Play:

* **Tag push** `v1.2.3`: version name 1.2.3, internal track, rolled out.

  ```bash
  git tag v1.0.1 && git push origin v1.0.1
  ```

* **By hand**: Actions → release → *Run workflow*: track (internal, alpha,
  production), status (`completed` rolls out, `draft` leaves the roll-out to
  the console), optional release notes, and *upload* off to only build (the
  bundle is attached to the run either way).
* A pull request that changes the workflow or the build scripts builds the
  bundle with the debug key and uploads nothing.

The version code is the commit count of the built commit, as in the local
script, so local and CI builds of the same commit agree and every later
commit gets a higher one. Release notes come from
`app/distribution/whatsnew/whatsnew-<locale>` (en-US, de-DE, ru-RU; at most
500 characters each); the *notes* input of a manual run replaces en-US only.
Update the three files in the pull request that brings the change.

The release build runs R8 (minify, `app/android/app/proguard-rules.pro`):
Google Play flags apps whose DEX code is less than 25 % obfuscated. The
mapping file is uploaded with the bundle, so Android vitals shows readable
stack traces, and the workflow fails when it is missing. R8 problems show at
run time, not in the build: try each release from internal testing (scan,
camera, statement import, folder access, widget, notifications) before
promoting it.
With managed publishing on, an approved release still waits for *Publish
changes* in the console; internal testing needs no review.

### One-time setup

1. **Service account for the Play API.** In Google Cloud
   (console.cloud.google.com), any project: enable the *Google Play Android
   Developer API*, create a service account (no roles needed), add a JSON
   key and download it. In Play Console → *Users and permissions* → *Invite
   new users*: the service account's email, app permission for AZ Budget
   with *Release to testing tracks* (and *Release to production* if CI may
   upload there). It can take up to a day before the API accepts the
   account.
2. **Repository secrets** (GitHub → Settings → Secrets and variables →
   Actions → *New repository secret*):

   | Secret | Value |
   |---|---|
   | `ANDROID_UPLOAD_KEYSTORE_BASE64` | the upload `.jks`, base64 |
   | `ANDROID_UPLOAD_STORE_PASSWORD` | `storePassword` from `app\android\key.properties` |
   | `ANDROID_UPLOAD_KEY_PASSWORD` | `keyPassword` from the same file |
   | `ANDROID_UPLOAD_KEY_ALIAS` | `keyAlias` from the same file |
   | `PLAY_SERVICE_ACCOUNT_JSON` | the whole JSON key file |

   The keystore as base64, on Windows (PowerShell), copied to the clipboard:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\az-budget-upload.jks")) | Set-Clipboard
   ```

   The workflow refuses to build without them (a bundle signed with the
   debug key would be rejected by Play), checks the signature of the built
   bundle and deletes the key from the runner afterwards.

The secrets are readable by workflows in this repository only; forks and
pull requests from forks do not get them. Whoever can push a `v*` tag can
release, so keep tag pushes to the maintainers.
