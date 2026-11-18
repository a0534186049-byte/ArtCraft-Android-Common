# Architecture and repository responsibilities

## Goal

Keep one shared Android build and distribution pipeline while every app remains an independent product with its own source, identity, package ID, signing key, release, and future app-specific changes.

## Components

### ArtCraft Android Common (this repository)

Owns only reusable infrastructure:

- The reusable workflow at .github/workflows/build-android-app.yml.
- Central allowlisted app profiles under apps/.
- The profile loader at scripts/load-app-profile.py.
- APK verification at scripts/verify-apk.sh.
- A local signing-key generator at scripts/generate-signing-key.sh.
- A reviewed ArtCraft Android Builder revision under versions/.

### ArtCraft Android Builder

The workflow checks out MostafaXS1/artcraft-android at an immutable commit SHA. This keeps the Android build implementation in its upstream project rather than creating an uncontrolled fork or copying a large amount of code into Common.

The pinned revision is:

2a03bb11c4d08e8ca3a5c96dc9fd942cbe7c29a9

PhotoCraft uses the builder's PhotoCraft adapter. GridCraft uses the builder's generated Android launcher. Shared Android services such as SAF integration, clipboard, touch and scroll handling, keyboard support, fonts, themes, and build generation are supplied by the builder revision.

### Individual app repositories

Each app repository owns:

- A small workflow entry point that calls this reusable workflow at a full Common commit SHA.
- Its own repository Secrets for a permanent signing key.
- Any app-specific adapter, patches, tests, or branding changes that are not appropriate for the common layer.

The app source itself is fetched from its official upstream repository by the builder. Common does not replace, fork, or rename that source.

## Build path

GridCraft or PhotoCraft repository
  -> reusable workflow at an exact Common commit SHA
  -> load and validate apps/<app>.json
  -> restore app-specific keystore from repository Secrets
  -> checkout immutable Android Builder commit
  -> fetch official Storytold source and apply Android integration
  -> build arm64 Android APK
  -> verify ZIP integrity, package ID, and signing certificate
  -> upload backup Actions Artifact
  -> replace APK asset in the app repository's fixed Release tag
  -> verify Release asset name and uploaded byte size

## Why pin by commit SHA

Apps should call the reusable workflow with the full SHA of a reviewed Common commit, not @main. The workflow checks out Common again at github.workflow_sha, so the profile and verifier match the workflow revision. The builder is pinned separately.

When Common changes, existing app repositories keep using their selected SHA until deliberately updated and tested.

## Adding another app later

1. Confirm the official upstream repository and its license.
2. Confirm that the builder supports the app and whether it needs a custom adapter.
3. Add a validated JSON profile under apps/.
4. Extend ALLOWED_APPS in scripts/load-app-profile.py.
5. Create the app repository's wrapper workflow and its own signing key.
6. Build, inspect the APK, and test install/update behavior before distributing it.

Do not copy one app's logo, custom adapter, source edits, or package settings into another app profile.
