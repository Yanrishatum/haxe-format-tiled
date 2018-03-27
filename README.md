# haxe-format-tiled
Tiled format support without additional dependencies (like OpenFL).

## Usage notes
* 2.0 version got quite a few changes in order to bring Tiled 1.1 support.  
* Apart from breaking changes there Reader works a bit differently now, and you can use same reader to parse all maps, TSX and template files from single Reader instead of need to create new one each time.  
* You can set `resolveTSX` and `resolveTypeTemplate` functions to Reader for it to automatically apply TSX/type templates during parsing.
* Current support for object templates is very basic, and not really tested.
* Since Tiled 1.0 layers can be nested with Groups, and if you need to use classic non-nested layers use `Tools.linearLayers`. (Read docs first)