# xLights Wiring Viewer

A Flutter app that shows the physical pixel wiring order of an xLights model —
browse the [xLights vendor catalog](https://github.com/xLightsSequencer/xLights/blob/master/download/xlights_vendors.xml)
or load a `.xmodel` file directly, and see a pan/zoomable diagram tracing node
1, 2, 3, ... through the model, colored by strand. Built for wiring props by
hand in the garage.

**Live web build:** https://computergeek1507.github.io/xlights_wiring_viewer/
(local file loading only — see [Known limitations](#known-limitations)).

## Features

- **Vendor catalog browser** — fetches `xlights_vendors.xml`, lists each
  vendor's models with thumbnail/dimensions/pixel count, downloads the
  `.xmodel` on demand.
- **Local file loading** — pick a `.xmodel` straight from the device,
  independent of the vendor catalog.
- **Wiring diagram** — a `CustomPainter` canvas draws the wiring path in node
  order under color-by-strand dots, with node 1 marked and an optional
  node-number label overlay (auto-hidden above ~150 nodes to stay readable).
- Supports both `.xmodel` flavors found in the wild: a vendor-distributed
  single-model file (`<custommodel>` at the document root) and xLights' own
  *File > Export Models* output (`<models type="exported"><model
  DisplayAs="..."> ...`).

### Supported model shapes

| Shape | Notes |
|---|---|
| Custom Model | full grid support (compressed + legacy formats) |
| Matrix | zigzag + alternate-node layouts |
| Single Line | |
| Arches | single/multi-arch |
| Tree | round (cone), flat, ribbon |
| Circle | single ring |
| Star | single layer |
| Spinner | |

Anything else (Wreath, Candy Cane, Icicles, Sphere, Window Frame, DMX
fixtures, ...) is rejected with a clear "unsupported model type" message
rather than silently failing. Geometry formulas were derived from xLights'
own `src-core/models/*.cpp` source, not guessed.

## Running it

```
flutter pub get
flutter run                 # picks whatever device/emulator is connected
flutter run -d chrome       # web
flutter build apk --release # Android APK
```

Android's Gradle/Kotlin versions are pinned in `android/settings.gradle.kts`
(AGP 8.7.3 / Kotlin 2.1.0) — a freshly-scaffolded newer toolchain breaks
`file_picker`'s build, so don't bump these without re-testing a release
build. CI (`.github/workflows/android.yml`) pins the same Flutter version
(3.44.0) for the same reason.

## Known limitations

- **Vendor browsing doesn't work on the web build.** Each vendor's model
  inventory is hosted on their own independent domain, and none of them send
  CORS headers permitting cross-origin browser fetches. This isn't fixable
  from the app itself — it would need a server-side proxy. The web build
  still works for the local-file-load flow and the top-level vendor list
  (hosted on GitHub, which does allow CORS).
- Layered/concentric Arches, multi-ring Circles, and multi-layer Stars
  (`LayerSizes` in xLights) fall back to the single-layer geometry.
- iOS isn't build-tested here (Windows dev machine, no Apple signing) but the
  project scaffold and every dependency are iOS-compatible by construction.

## Project layout

```
lib/
  models/            Vendor, VendorModel, and the shape-agnostic WiredModel/WiredNode
  services/
    geometry/        One file per model shape + the shared Matrix/Tree buffer helper
    vendor_catalog_service.dart   fetch + offline cache for vendor/model XML
    xmodel_importer.dart          dispatches a parsed .xmodel to the right geometry builder
  ui/                Vendor list -> vendor's model list -> model detail -> wiring view
  widgets/
    wiring_canvas.dart            the wiring-diagram CustomPainter
test/
  geometry/          per-shape node-count/order sanity tests + import format regression tests
```

## Testing

```
flutter analyze
flutter test
```

Geometry tests assert node count, contiguous 1..N ordering, and rough
bounding-box shape for each supported model type, plus round-trip and
regression coverage for both `.xmodel` file formats.
