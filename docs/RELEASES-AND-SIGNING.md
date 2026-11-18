# Signing and GitHub Releases

## Why signing is permanent

Android accepts an in-place update only when the new APK uses the same application ID and a compatible signing certificate as the installed app. Each ArtCraft app therefore has:

- One fixed application ID in its profile.
- One permanent private keystore per app repository.
- One fixed GitHub Release tag.
- One APK asset whose contents are replaced after every successful build.

Do not regenerate or replace a signing key after the first distributed APK. Losing the key can prevent users from installing future updates over the existing app.

## Create a key for each app

Run from a clone of this Common repository:

    bash scripts/generate-signing-key.sh gridcraft
    bash scripts/generate-signing-key.sh photocraft

Run only the command for the app whose key you are preparing. The script refuses to overwrite existing key files. It creates local files under keys/, which is ignored by Git:

- <app>-release.jks
- <app>-release-password.txt
- <app>-release-keystore-base64.txt

It prints the SHA-256 certificate fingerprint. Back up the original keystore, password, and fingerprint securely and offline. Never commit any file from keys/.

## Add GitHub Actions Secrets

In each app repository separately:

1. Open the repository on GitHub.
2. Select Settings, then Secrets and variables, then Actions.
3. Choose New repository secret.
4. Add these three Secrets:

| Secret name | Value |
|---|---|
| ARTCRAFT_SIGNING_KEYSTORE_BASE64 | Entire contents of that app's base64 keystore file |
| ARTCRAFT_SIGNING_PASSWORD | Entire contents of that app's password file |
| ARTCRAFT_EXPECTED_CERT_SHA256 | SHA-256 fingerprint printed by the key-generation script |

Do not use the same key for different app repositories. Do not send secret values in chat or add them to a workflow file.

## How publishing works

The reusable workflow:

1. Restores the app's keystore in the temporary runner.
2. Builds the release APK.
3. Checks ZIP integrity, package ID, and APK signature.
4. Compares the signing certificate to the configured SHA-256 fingerprint.
5. Uploads an Actions Artifact as a backup.
6. Creates the fixed Release on the first successful build, or replaces the existing asset with gh release upload --clobber.
7. Reads the Release Assets back from GitHub and verifies the exact APK filename and byte size.

No new Release is created for each build. The asset keeps the .apk extension. The build fails if the expected asset is not present after upload.

## Package IDs and release tags

| App | Application ID | Release tag | Asset |
|---|---|---|---|
| GridCraft | com.artcraft.gridcraft | gridcraft-latest | GridCraft.apk |
| PhotoCraft | com.artcraft.photocraft | photocraft-latest | PhotoCraft.apk |

Confirm an app's ID before its first distributed build. Once users have installed an APK, do not change its ID or signing key.
