# Third-party notices

Licence texts for Dart/Flutter packages are bundled by Flutter and shown in
the app under **Settings → Open-source licences** (`showLicensePage`).
`tool/check_licenses.sh` lists the resolved licence family of every
dependency and fails on GPL/AGPL.

## Runtime dependencies (direct)

| Package | Version | Licence | Use |
|---|---|---|---|
| Flutter SDK / Dart SDK | 3.27.3 / 3.6.1 | BSD-3-Clause | Framework |
| flutter_riverpod / riverpod | 2.6.1 | MIT | State management, DI |
| go_router | 16.1.0 | BSD-3-Clause | Routing |
| camera (+ camera_android_camerax, camera_avfoundation) | 0.11.2 | BSD-3-Clause | Camera on Android/iOS |
| google_mlkit_face_detection / google_mlkit_commons | 0.13.1 / 0.11.0 | MIT (plugin) | Face detection bridge |
| Google ML Kit Face Detection SDK (native) | via plugin | Google ML Kit Terms of Service (proprietary, free) | On-device face detection, Android/iOS |
| sembast / sembast_web | 3.8.3 / 2.4.0+4 | BSD-3-Clause | Local database |
| path_provider | 2.1.5 | BSD-3-Clause | App directories |
| permission_handler | 11.4.0 | MIT | Camera permission status |
| package_info_plus | 9.0.1 | BSD-3-Clause | Version display |
| share_plus | 12.0.2 | BSD-3-Clause | Export via share sheet |
| intl / flutter_localizations | 0.19.0 / SDK | BSD-3-Clause | Localisation, dates |
| web | 1.1.1 | BSD-3-Clause | Browser camera interop |
| uuid | 4.6.0 | MIT | Record IDs |

Transitive dependencies are BSD, MIT or Apache-2.0 (see the script output).

## Bundled assets

| Asset | Licence | Source |
|---|---|---|
| Roboto font (Light, Regular, Medium, Bold) | Apache License 2.0 (`assets/fonts/Roboto_LICENSE.txt`) | Copied from the Flutter SDK's `material_fonts` artifact |
| Material Icons (tree-shaken) | Apache License 2.0 | Flutter SDK |

## Algorithms (implemented from publications; no code copied)

* POS — W. Wang, A. C. den Brinker, S. Stuijk, G. de Haan, "Algorithmic
  Principles of Remote PPG", IEEE TBME 64(7), 2017.
* CHROM — G. de Haan, V. Jeanne, "Robust Pulse Rate From Chrominance-Based
  rPPG", IEEE TBME 60(10), 2013.
* Skin mask bounds — D. Chai, K. N. Ngan, "Face segmentation using
  skin-color map in videophone applications", IEEE TCSVT 9(4), 1999.

## Not included

No code, weights or data from rPPG-Toolbox (RAIL v1.1), pyVHR (GPL-3.0),
UBFC-rPPG, PURE, SCAMPS, BP4D+ or iBVP are included. See
docs/model_evaluation.md.
