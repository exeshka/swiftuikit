part of '../swift_text.dart';

const _glyphAtlasPagePixels = 2048;
const _glyphAtlasEdgePaddingPixels = 1;

class _GlyphAtlas {
  _GlyphAtlas._(this.entries, this._images);

  factory _GlyphAtlas.build(_TextLayout layout, double devicePixelRatio) {
    final ratio = math.max(1.0, devicePixelRatio);
    final pages = <_AtlasPagePlan>[];
    final cells = <_AtlasCellPlan>[];
    var page = _AtlasPagePlan();
    pages.add(page);
    var x = 0;
    var y = 0;
    var rowHeight = 0;

    for (final glyph in layout.glyphs) {
      final bounds = glyph.bounds;
      if (bounds == null || bounds.isEmpty) continue;
      final fontSize = glyph.style.fontSize ?? 14;
      final sigma = math.max(0.75, fontSize * _glyphBlurFactor) * 1.08;
      final padding = (sigma * 3 * ratio).ceil() + _glyphAtlasEdgePaddingPixels;
      final contentWidth = math.max(1, (bounds.width * ratio).ceil());
      final contentHeight = math.max(1, (bounds.height * ratio).ceil());
      final cellWidth = contentWidth + padding * 2;
      final cellHeight = contentHeight + padding * 2;
      if (cellWidth > _glyphAtlasPagePixels ||
          cellHeight > _glyphAtlasPagePixels) {
        continue;
      }

      if (x > 0 && x + cellWidth > _glyphAtlasPagePixels) {
        x = 0;
        y += rowHeight;
        rowHeight = 0;
      }
      if (y > 0 && y + cellHeight > _glyphAtlasPagePixels) {
        page = _AtlasPagePlan();
        pages.add(page);
        x = 0;
        y = 0;
        rowHeight = 0;
      }

      final cell = _AtlasCellPlan(
        glyph: glyph,
        bounds: bounds,
        x: x,
        y: y,
        width: cellWidth,
        height: cellHeight,
        padding: padding,
        page: page,
      );
      page.cells.add(cell);
      page.usedWidth = math.max(page.usedWidth, x + cellWidth);
      page.usedHeight = math.max(page.usedHeight, y + cellHeight);
      cells.add(cell);
      x += cellWidth;
      rowHeight = math.max(rowHeight, cellHeight);
    }

    final images = <ui.Image>[];
    final imageByPage = Map<_AtlasPagePlan, ui.Image>.identity();
    for (final page in pages) {
      if (page.cells.isEmpty) continue;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final cell in page.cells) {
        canvas.save();
        canvas.clipRect(cell.sourceRect);
        canvas.translate(
          cell.x + cell.padding.toDouble(),
          cell.y + cell.padding.toDouble(),
        );
        canvas.scale(ratio);
        canvas.translate(-cell.bounds.left, -cell.bounds.top);
        canvas.clipRect(cell.bounds.inflate(0.6));
        layout.painter.paint(canvas, Offset.zero);
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final image = picture.toImageSync(page.usedWidth, page.usedHeight);
      picture.dispose();
      images.add(image);
      imageByPage[page] = image;
    }

    final entries = Map<_Glyph, _GlyphAtlasEntry>.identity();
    for (final cell in cells) {
      final image = imageByPage[cell.page];
      if (image == null) continue;
      final padding = cell.padding / ratio;
      entries[cell.glyph] = _GlyphAtlasEntry(
        image: image,
        sourceRect: cell.sourceRect,
        logicalBounds: Rect.fromLTWH(
          cell.bounds.left - padding,
          cell.bounds.top - padding,
          cell.width / ratio,
          cell.height / ratio,
        ),
      );
    }
    return _GlyphAtlas._(entries, images);
  }

  final Map<_Glyph, _GlyphAtlasEntry> entries;
  final List<ui.Image> _images;

  void dispose() {
    for (final image in _images) {
      image.dispose();
    }
  }
}

class _GlyphAtlasEntry {
  const _GlyphAtlasEntry({
    required this.image,
    required this.sourceRect,
    required this.logicalBounds,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect logicalBounds;
}

class _AtlasPagePlan {
  final List<_AtlasCellPlan> cells = <_AtlasCellPlan>[];
  int usedWidth = 0;
  int usedHeight = 0;
}

class _AtlasCellPlan {
  const _AtlasCellPlan({
    required this.glyph,
    required this.bounds,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.padding,
    required this.page,
  });

  final _Glyph glyph;
  final Rect bounds;
  final int x;
  final int y;
  final int width;
  final int height;
  final int padding;
  final _AtlasPagePlan page;

  Rect get sourceRect => Rect.fromLTWH(
    x.toDouble(),
    y.toDouble(),
    width.toDouble(),
    height.toDouble(),
  );
}
