# ArtCraft Android Common

Shared build, verification, signing and GitHub Release automation for the independent ArtCraft Android app repositories.

This repository is the **shared infrastructure layer**. It does not contain or replace the applications' upstream source code, logos, icons, product names, or app-specific design.

## Current app profiles

| Profile | App | Upstream source | Android package ID | Fixed Release tag |
|---|---|---|---|---|
| `gridcraft` | GridCraft (spreadsheet app) | `storytold/gridcraft` | `com.artcraft.gridcraft` | `gridcraft-latest` |
| `photocraft` | PhotoCraft (image editor) | `storytold/photocraft` | `com.artcraft.photocraft` | `photocraft-latest` |

The package IDs above are the initial project defaults. **Do not change an ID after distributing an installable APK**, because Android treats a different ID as a different application.

## What is shared here

- One reusable GitHub Actions workflow for Android builds.
- A pinned reference to the upstream ArtCraft Android Builder.
- Central per-app build/release profiles.
- APK package/signature/ZIP verification.
- Fixed-tag GitHub Release publication that replaces the existing APK asset.
- Documentation for signing, app repositories, and safe updates.

The official app source is checked out by the builder during each build. It is not copied into this repository. The builder and the upstream applications retain their own licenses, notices, and attribution.

## Build architecture

1. An individual app repository calls `.github/workflows/build-android-app.yml` from this repository.
2. The workflow checks out this repository at the exact commit containing the reusable workflow.
3. It checks out the pinned ArtCraft Android Builder revision.
4. The builder fetches the selected official upstream app source and creates the Android APK.
5. The workflow verifies that the APK is a valid ZIP, has the expected Android package ID, and is signed with the configured signing key.
6. The APK is uploaded as a backup Actions Artifact.
7. The APK is uploaded to the app repository's **existing fixed GitHub Release**. The asset is replaced in place; a new Release is not created for every build.
8. The workflow checks the Release Assets and verifies that the expected APK asset exists with the expected size.

## Using this repository from an app repository

Call the reusable workflow from the app repository. Replace `<COMMON_COMMIT_SHA>` with the full commit SHA of this repository (not `main`), so future Common changes cannot silently change an app's build pipeline.

```yaml
name: Build Android APK

on:
  workflow_dispatch:
    inputs:
      source_version:
        description: Upstream source version
        type: choice
        required: true
        default: stable
        options:
          - stable
          - main

permissions:
  contents: write

jobs:
  build:
    uses: a0534186049-byte/ArtCraft-Android-Common/.github/workflows/build-android-app.yml@<COMMON_COMMIT_SHA>
    with:
      app: gridcraft
      source_version: ${{ inputs.source_version || 'stable' }}
    secrets:
      ARTCRAFT_SIGNING_KEYSTORE_BASE64: ${{ secrets.ARTCRAFT_SIGNING_KEYSTORE_BASE64 }}
      ARTCRAFT_SIGNING_PASSWORD: ${{ secrets.ARTCRAFT_SIGNING_PASSWORD }}
      ARTCRAFT_EXPECTED_CERT_SHA256: ${{ secrets.ARTCRAFT_EXPECTED_CERT_SHA256 }}
```

For PhotoCraft, change only `app: gridcraft` to `app: photocraft`. The central profile supplies the display name, package ID, Release tag and APK asset name.

Each app repository must have its **own persistent signing key** and the three repository Secrets shown above. Never commit a keystore, password, token, or encoded secret to Git.

## Build pin

The default builder revision is recorded in `versions/artcraft-android-builder.ref` and in the reusable workflow's `builder_ref` default. Update that pin deliberately, review the builder changes, and test both app builds before adopting a new revision.

## Repository boundaries

- This Common repository owns shared build and release automation.
- GridCraft's repository owns GridCraft-specific workflow entry points and later app-specific changes.
- PhotoCraft's repository owns PhotoCraft-specific workflow entry points and later app-specific changes.
- WordCraft remains an independent, working repository and is not modified by this setup.
- Upstream source repositories remain the source of truth for the actual application code.

See [Architecture](docs/ARCHITECTURE.md), [Signing and Releases](docs/RELEASES-AND-SIGNING.md), and [App Profiles](docs/APP-REPOSITORIES.md).
