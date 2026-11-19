# Android build hardening checklist

This document records concrete failure modes observed in the GridCraft and WordCraft Android workflows and the safeguards used to prevent repeated edit-build-fail cycles.

## Before changing source

1. Pin the application source to an immutable commit SHA. Do not silently build a moving `main` branch when patches depend on exact source structure.
2. Inspect the exact pinned source files and nearby function signatures before writing a patch.
3. Require each patch anchor to be unique. If an anchor is missing or duplicated, stop with the file path, patch name and counts; never guess a nearby replacement.
4. Keep app-specific patch scripts separate from the shared builder and from other applications.

## Validate patch scripts before building

1. Run the patcher through the configured Python interpreter's syntax compiler (`python -m py_compile`).
2. Apply the patcher once, then run it a second time. The second run must be a no-op. This detects non-idempotent patch operations before compilation.
3. Do not rely on a successful string replacement as evidence that the generated source compiles.
4. Preserve the build log from the first failed command. Avoid swallowing the original error behind a generic failure message.

## Validate generated Rust before an APK build

For a temporary, patched source checkout:

1. Run `cargo fmt --all` to normalize formatting in that temporary checkout.
2. Run `cargo fmt --all -- --check` immediately afterward as a non-mutating syntax/format gate.
3. Run focused tests for every behavior changed by the patch, including the integration-test targets that compile the full integration test crate.
4. Run the app's normal Android build only after the targeted tests pass.
5. Verify package ID, APK integrity and signing certificate after the build. Publish the Release asset only after all checks pass, and verify the asset exists in Release Assets.

Formatting must happen in the CI checkout created for the build, never by modifying or committing an upstream source repository as a side effect.

## What the recent failures taught us

- GridCraft: the per-tab ribbon change modified `RibbonOverflow::get` to require a tab name. The implementation compiled, but existing integration tests still called the old one-argument API. The fix was to update the test helper and all callers to query the active tab. A subsequent preflight caught formatting differences in the generated Rust before compilation.
- WordCraft: exact text anchors became stale after upstream source refactors; one preparation script also used `re` without importing it. Another run generated Rust with an unmatched delimiter, and another hit a new struct field that was not handled in a destructuring pattern. These are patch maintenance and preflight issues, not evidence of an Android SDK download failure.

## Non-negotiable rules

- Never weaken or skip a failing test just to produce an APK.
- Never replace missing or malformed source with silent defaults to make a build pass.
- Never publish a debug-signed APK as a stable update.
- Keep package ID and persistent signing certificate stable for an app's lifetime.
- Keep changes scoped to the target app and the shared workflow; do not copy one app's code, brand, assets or signing key into another.
- Treat a cancelled workflow as a cancelled run, not a test failure. A repeated failure is a signal to inspect and fix the root cause before making another speculative source edit.
