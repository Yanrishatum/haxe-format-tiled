# haxe-format-tiled
Tiled format support without additional dependencies (like OpenFL).

## Feature-support
* Currently library supports Tiled 1.1
When Tiled will get new features that you will need to utilize, please create an Issue (or better a PR ;) ). I do not watch Tiled development closely, but will provide library updates for new features.

## Usage notes
* 2.0 version got quite a few changes in order to bring Tiled 1.1 support.  
* Apart from breaking changes there Reader works a bit differently now, and you can use same reader to parse all maps, TSX and template files from single Reader instead of need to create new one each time.  
* You can set `resolveTSX` and `resolveTypeTemplate` functions to Reader for it to automatically apply TSX/type templates during parsing.
* Current support for object templates is very basic, and not really tested.
* Since Tiled 1.0 layers can be nested with Groups, and if you need to use classic non-nested layers use `Tools.linearLayers`. (Read docs first)

## License
Library source code belongs to public domain with exception of assets used in test code.
* `test/assets` taken from official Tiled sample folder, see their [AUTHORS](https://github.com/bjorn/tiled/blob/master/AUTHORS#L264-L273) file for license info.
* `test/tile_flags/files` tileset licensed under CC-BY 3.0 and belongs to Buch (See: [OpenGameArt.org](https://opengameart.org/content/outdoor-tiles-again))