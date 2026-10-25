# FikaGo image package compatibility patch

This is the `image` 4.11.0 package source with one compatibility change in
`lib/src/formats/png_decoder.dart`: PNG data uses `ZLibDecoder.decodeBytes`
from `archive` 4.0.9. The upstream `image` 4.11.0 code calls `decodeLazy`,
which is only present in newer `archive` releases, while `pdf` 3.12.0 requires
`archive <4.1.0`.
