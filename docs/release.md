# Releasing to Google Play

The goal for now: the app on the **internal testing** track, installed and
updated through Play for a handful of named testers. Production (and the
closed test with 12 testers for 14 days that a personal developer account
needs before it) comes later and reuses everything below.

## One-time setup

1. **Developer account.** https://play.google.com/console, personal account,
   25 USD once, identity verification (takes a day or two).
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
- **Target audience**: 18 and over. **News app**: no. **COVID-19**: no.
- **Data safety**: no data collected, no data shared by default. If you want
  to be precise about the optional OpenAI import: "Financial info > Other
  financial info", shared, optional, user-initiated, for app functionality,
  not encrypted in transit claim is "yes" (HTTPS), deletable (nothing is
  stored). Simpler and still truthful: declare only what is collected
  (nothing) and mention OpenAI in the privacy policy, which is done.
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

## Later: closed testing and production

A personal account created after November 2023 needs a closed test with at
least 12 testers opted in for 14 consecutive days before it can apply for
production access. Internal testing does not count. Everything above stays
the same; the closed track just gets a bigger tester list, and after the 14
days the console offers "Apply for production access".
