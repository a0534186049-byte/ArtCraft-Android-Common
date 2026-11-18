# Third-party notices

This repository contains the shared workflow, profile loader, verification helpers, and documentation. Application source code is checked out at build time and is not bundled into this repository.

## ArtCraft Android Builder

- Repository: https://github.com/MostafaXS1/artcraft-android
- Pinned revision: 2a03bb11c4d08e8ca3a5c96dc9fd942cbe7c29a9
- License: MIT
- The builder repository's copyright and license terms remain applicable to its code. Its own LICENSE, dependency licenses, vendored notices, and attribution files are retained in the checked-out builder repository.
- This Common repository does not claim ownership of the builder or the upstream apps.

## GridCraft upstream source

- Repository: https://github.com/storytold/gridcraft
- The upstream repository carries LICENSE-APACHE, LICENSE-MIT, and NOTICE.
- Build distributions must preserve the applicable license texts, NOTICE, and individual asset notices as required by those licenses.

## PhotoCraft upstream source

- Repository: https://github.com/storytold/photocraft
- The upstream repository carries LICENSE-APACHE, LICENSE-MIT, and NOTICE.
- It also contains asset-specific license and notice files. Build distributions must preserve applicable notices and attribution.

## Scope

The Common repository deliberately does not copy app source, logos, icons, UI assets, or the builder's vendored dependency tree. At build time those materials are retrieved from their own repositories, where their original license and attribution files remain available. Review the exact upstream revision and license files whenever changing the builder pin or app source selection.
