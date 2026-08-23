# Changelog

All notable changes to xModel Wiring Viewer are documented here.

## [1.0.0] - 2026-08-23

Initial release.

### Added
- Browse the xLights vendor catalog — search dozens of vendors and hundreds
  of prop models without leaving the app
- Load a `.xmodel` file directly from the device
- Load an `xlights_rgbeffects.xml` show file to browse every model already
  in a show
- Physical wiring order diagram: pan/zoom, color-coded by strand/arm/row,
  node 1 and the last node marked distinctly
- Front (display) vs backside (wiring) view toggle
- Node number label toggle
- Print or export a wiring diagram to PDF, with a white/high-contrast
  palette used only for the printed page
- Geometry support for Custom Model (grid), Matrix, Single Line, Arches
  (including layered/concentric), Tree (round, flat, ribbon), Circle
  (including multi-ring), Star (including layered/concentric), and Spinner
- Web build with a CORS proxy for full vendor browsing and `.xmodel`
  downloads (native platforms need no proxy)
- Android release build with a signed App Bundle; iOS-compatible project
  scaffold (untested — no Apple signing available in development)
