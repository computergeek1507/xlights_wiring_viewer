/// One pixel's position in a Matrix/Tree buffer, already zigzag/alternate
/// adjusted. List order (from [buildMatrixBuffer]) IS wiring order — the
/// first entry is node 1.
class BufferPixel {
  final int col;
  final int row;
  final int strandIndex;

  const BufferPixel({required this.col, required this.row, required this.strandIndex});
}

/// Shared row/strand layout used by both Matrix and Tree models (Tree reuses
/// Matrix's buffer before projecting it onto a cone/fan shape). Mirrors
/// xLights' `MatrixModel`/`VMatrixModel` buffer construction:
///
/// - [numStrings] * [strandsPerString] = total physical wired strands.
/// - [nodesPerString] / [strandsPerString] = pixels per physical strand.
/// - [zigzag] (xLights default, disabled by `NoZigZag="true"`): odd-indexed
///   strands run in the opposite direction, matching serpentine LED-strip
///   wiring so the buffer stays a rectangle even though physical strands
///   alternate direction.
/// - [alternateNodes]: interleaves one physical strand's pixels into two
///   offset rows (folded/ribbon panel), first half of the strand into an
///   even row left-to-right, second half into the next odd row right-to-left.
/// - [vertical]: strand axis is the column instead of the row (columns are
///   the physical strands; rows are position-along-strand).
List<BufferPixel> buildMatrixBuffer({
  required int numStrings,
  required int nodesPerString,
  required int strandsPerString,
  required bool vertical,
  bool zigzag = true,
  bool alternateNodes = false,
}) {
  final strandsPerStringSafe = strandsPerString < 1 ? 1 : strandsPerString;
  final numStrands = (numStrings < 1 ? 1 : numStrings) * strandsPerStringSafe;
  final pixelsPerStrand =
      (nodesPerString / strandsPerStringSafe).round().clamp(1, 1 << 20);

  final pixels = <BufferPixel>[];
  for (var strand = 0; strand < numStrands; strand++) {
    for (var pos = 0; pos < pixelsPerStrand; pos++) {
      int primary; // strand axis (row in horizontal orientation)
      int secondary; // along-strand axis (col in horizontal orientation)
      if (alternateNodes) {
        final half = (pixelsPerStrand / 2).ceil();
        if (pos < half) {
          primary = strand * 2;
          secondary = pos;
        } else {
          primary = strand * 2 + 1;
          secondary = pixelsPerStrand - pos - 1;
        }
      } else {
        primary = strand;
        secondary = (zigzag && strand.isOdd) ? (pixelsPerStrand - pos - 1) : pos;
      }
      pixels.add(BufferPixel(
        col: vertical ? primary : secondary,
        row: vertical ? secondary : primary,
        strandIndex: strand,
      ));
    }
  }
  return pixels;
}
