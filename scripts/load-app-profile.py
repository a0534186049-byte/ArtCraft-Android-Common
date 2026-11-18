#!/usr/bin/env python3
"""Validate an app slug and export its central JSON profile to GitHub Actions."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ALLOWED_APPS = {"gridcraft", "photocraft"}
PACKAGE_RE = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")
TAG_RE = re.compile(r"^[A-Za-z0-9._-]+$")
ASSET_RE = re.compile(r"^[A-Za-z0-9._-]+\.apk$")
SOURCE_REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")


def fail(message: str) -> None:
    print(f"::error::{message}", file=sys.stderr)
    raise SystemExit(2)


def main() -> None:
    if len(sys.argv) != 2:
        fail("Usage: load-app-profile.py <gridcraft|photocraft>")

    app = sys.argv[1].strip().lower()
    if app not in ALLOWED_APPS:
        fail(f"Unsupported app profile: {app!r}")

    root = Path(__file__).resolve().parents[1]
    profile_path = root / "apps" / f"{app}.json"
    try:
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"Cannot read {profile_path}: {exc}")

    required = (
        "slug", "display_name", "upstream_repository", "application_id",
        "release_tag", "release_asset_name", "adapter",
    )
    missing = [key for key in required if not isinstance(profile.get(key), str) or not profile[key].strip()]
    if missing:
        fail(f"Profile {app} has missing or empty fields: {', '.join(missing)}")
    if profile["slug"] != app:
        fail(f"Profile slug mismatch: expected {app}, got {profile['slug']}")
    if not PACKAGE_RE.fullmatch(profile["application_id"]):
        fail(f"Invalid Android application ID: {profile['application_id']}")
    if not TAG_RE.fullmatch(profile["release_tag"]):
        fail(f"Invalid GitHub Release tag: {profile['release_tag']}")
    if not ASSET_RE.fullmatch(profile["release_asset_name"]):
        fail(f"Invalid APK asset name: {profile['release_asset_name']}")

    source_repo = profile.get("android_source_repository", "")
    source_commit = profile.get("android_source_commit", "")
    if source_repo and not SOURCE_REPO_RE.fullmatch(source_repo):
        fail(f"Invalid Android source repository: {source_repo!r}")
    if source_commit and not COMMIT_RE.fullmatch(source_commit):
        fail(f"Invalid Android source commit: {source_commit!r}")
    if source_commit and not source_repo:
        fail("android_source_commit requires android_source_repository")

    outputs = {
        "app": app,
        "android_source_repository": source_repo,
        "android_source_commit": source_commit,
        "display_name": profile["display_name"],
        "application_id": profile["application_id"],
        "release_tag": profile["release_tag"],
        "release_asset_name": profile["release_asset_name"],
        "upstream_repository": profile["upstream_repository"],
        "adapter": profile["adapter"],
    }
    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as output:
            for key, value in outputs.items():
                if "\n" in value or "\r" in value:
                    fail(f"Invalid newline in profile field: {key}")
                output.write(f"{key}={value}\n")
    else:
        print(json.dumps(outputs, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
