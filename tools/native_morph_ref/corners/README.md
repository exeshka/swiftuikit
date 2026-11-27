# Corner / silhouette tools

Frames: `swiftc -O frames_pts.swift -o frames_pts && mkdir sl && ./frames_pts sl.mov sl > sl.pts` (slowed native recording, PNG per frame + presentation times).

* `fit_corners.py FRAMES PTS T0 FIRST LAST STEP OUT.json [--ellip|--rotate]` — silhouette fit (4 radii, optionally elliptical corners / rotation).
* `fit_union.py ...` — two plates with smooth union (the "neck").
* `fit_edges.py open|close` — spring (+slow tail) per edge from the fitted silhouettes.
* `gen_knots.py` — radius multipliers -> `data/radii_knots.json`, `morph_knots.dart`.
* `morph_model.dart`, `morph_iou_test.dart` — our silhouette (springs and radii read from `lib/src/components/glass_menu.dart`) vs native, IoU per tau:
  `flutter test tools/native_morph_ref/corners/morph_iou_test.dart` (writes `out/iou_*.txt`, `out/ours_*.json`).
* `score_vs_evidence.py FRAMES open|close` — the same shapes against the pixels (`out/evidence_*.txt`).
* `make_tables.py` — markdown tables for MORPH_SPEC.md section 7; `overlay.py` — picture of evidence + fitted contour.
