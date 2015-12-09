package format.tmx;
import format.tmx.Data.TmxImage;
import format.tmx.Data.TmxTileLayer;
import haxe.io.Bytes;

/** Map orientation */
enum TmxOrientation
{
  Orthogonal;
  Isometric;
  /** Since 0.9 */
  Staggered;
  /** Since 0.11 (git) */
  Hexagonal;
  
  Unknown(value:String);
}

/** Rendering order of tiles */
enum TmxRenderOrder
{
  RightDown;
  RightUp;
  LeftDown;
  LeftUp;
  Unknown(value:String);
}

enum TmxStaggerIndex
{
  Even;
  Odd;
}

enum TmxStaggerDirection
{
  Rows;
  Columns;
}

/** General .tmx map file */
typedef TmxMap =
{
  /** The TMX format version, generally 1.0. */
  var version:String;
  /** Map orientation. */
  var orientation:TmxOrientation;
  /** The map width in tiles. */
  var width:Int;
  /** The map height in tiles. */
  var height:Int;
  /**
   * The width of a tile.
   * 
   * The tilewidth and tileheight properties determine the general grid size of the map.
   * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
   * */
  var tileWidth:Int;
  /**
   * The height of a tile.
   * 
   * The tilewidth and tileheight properties determine the general grid size of the map.
   * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
   */
  var tileHeight:Int;
  /** The background color of the map. Since 0.9, optional. */
  @:optional var backgroundColor:Int;
  /** The order in which tiles on tile layers are rendered. Since 0.10, but only for orthogonal orientation. */
  @:optional var renderOrder:TmxRenderOrder;
  /** Since 0.11 (git) */
  @:optional var staggerIndex:TmxStaggerIndex;
  /** Since 0.11 (git) */
  @:optional var staggerDirection:TmxStaggerDirection;
  /** Since 0.11 (git) */
  @:optional var hexSideLength:Int;
  
  /** Properties of the map */
  @:optional var properties:Map<String, String>;
  
  /** Tilesets used in map */
  var tilesets:Array<TmxTileset>;
  /** Array of all layers in map. Tile layers, object groups and image layers.*/
  var layers:Array<TmxLayer>;
}

/**
 * Tileset
 * TSX files does not contains firstGID and source.
 * TMX Tilesets can be both full tilesets or point to TSX file. In that case it contains only firstGID and source. 
 * You can merge TSX file TMX Tileset into one by using `new Reader(tsxXML).readTSX(tmxTileset);`.
 */
typedef TmxTileset =
{
  /** The first global tile ID of this tileset (this global ID maps to the first tile in this tileset). */
  @:optional var firstGID:Null<Int>;
  /** If this tileset is stored in an external TSX (Tile Set XML) file, this attribute refers to that file. That TSX file has the same structure as the <tileset> element described here. (There is the firstgid attribute missing and this source attribute is also not there. These two attributes are kept in the TMX map, since they are map specific.) */
  @:optional var source:String;
  /** The name of this tileset. */
  @:optional var name:String;
  /** The (maximum) width of the tiles in this tileset. */
  @:optional var tileWidth:Null<Int>;
  /** The (maximum) height of the tiles in this tileset. */
  @:optional var tileHeight:Null<Int>;
  /** The spacing in pixels between the tiles in this tileset (applies to the tileset image). */
  @:optional var spacing:Null<Int>;
  /** The margin around the tiles in this tileset (applies to the tileset image). */
  @:optional var margin:Null<Int>;
  
  /** This element is used to specify an offset in pixels, to be applied when drawing a tile from the related tileset. When not present, no offset is applied. Since 0.8 */
  @:optional var tileOffset:TmxTileOffset;
  /** Since 0.8 */
  @:optional var properties:Map<String, String>;
  /**
   * As of the current version of Tiled Qt, each tileset has a single image associated with it, 
   * which is cut into smaller tiles based on the attributes defined on the tileset element. 
   * Later versions may add support for adding multiple images to a single tileset, as is possible in Tiled Java.
   */
  @:optional var image:TmxImage;
  /** Terrain type defines. Since 0.9 */
  @:optional var terrainTypes:Array<TmxTerrain>;
  /** Extended tiles data.  */
  @:optional var tiles:Array<TmxTilesetTile>;
  
}

/** This element is used to specify an offset in pixels, to be applied when drawing a tile from the related tileset. When not present, no offset is applied. */
typedef TmxTileOffset =
{
  /** Horizontal offset in pixels */
  var x:Int;
  /** Vertical offset in pixels (positive is down) */
  var y:Int;
}

/**
 * As of the current version of Tiled Qt, each tileset has a single image associated with it, 
 * which is cut into smaller tiles based on the attributes defined on the tileset element. 
 * Later versions may add support for adding multiple images to a single tileset, as is possible in Tiled Java.
 */
typedef TmxImage =
{
  /** Used for embedded images, in combination with a data child element. Valid values are file extensions like png, gif, jpg, bmp, etc. (since 0.9.0) */
  @:optional var format:String;
  /** Used by some versions of Tiled Java. Deprecated and unsupported by Tiled Qt. */
  @:optional var id:String;
  /** The reference to the tileset image file (Tiled supports most common image formats). */
  var source:String;
  /**
   * Defines a specific color that is treated as transparent (example value: "#FF00FF" for magenta). 
   * Up until Tiled 0.10, this value is written out without a # but this is planned to change.
   */
  @:optional var transparent:Null<Int>;
  /** The image width in pixels (optional, used for tile index correction when the image changes) */
  @:optional var width:Null<Int>;
  /** The image height in pixels (optional) */
  @:optional var height:Null<Int>;
  /** Since 0.9 */
  @:optional var data:TmxData;
}

typedef TmxTerrain =
{
  /** The name of the terrain type. */
  var name:String;
  /** The local tile-id of the tile that represents the terrain visually. */
  var tile:Int;
  
  @:optional var properties:Map<String, String>;
}

typedef TmxTilesetTile =
{
  /** The local tile ID within its tileset. */
  var id:Int;
  /**
   * Defines the terrain type of each corner of the tile,
   * given as comma-separated indexes in the terrain types array in the order 
   * top-left, top-right, bottom-left, bottom-right. Leaving out a value means
   * that corner has no terrain. (optional) (since 0.9.0)
   */
  @:optional var terrain:String;
  /**
   * A percentage indicating the probability that this tile is chosen when it
   * competes with others while editing with the terrain tool. (optional) (since 0.9.0)
   */
  @:optional var probability:Float;
  
  @:optional var properties:Map<String, String>;
  /**
   * Since 0.9
   */
  @:optional var image:TmxImage;
  /**
   * Since 0.10.
   * This group represents collision of tile and never contains Tile object type.
   */
  @:optional var objectGroup:TmxObjectGroup;
  /**
   * Since ???.
   * Present, if tile does not static and contains animation.
   */
  @:optional var animation:Array<TmxTilesetTileFrame>;
}

/**
 * Animation frame of a single tile in tileset.
 */
typedef TmxTilesetTileFrame =
{
  /** Tile id of frame. Id is local to Tileset and always part of that tileset. */
  var tileId:Int;
  /** Display duration of frame in milliseconds. */
  var duration:Int;
}

enum TmxLayer
{
  TileLayer(layer:TmxTileLayer);
  ObjectGroup(group:TmxObjectGroup);
  ImageLayer(layer:TmxImageLayer);
}

typedef TmxBaseLayer =
{
  /** The name of the layer. */
  var name:String;
  /** The x coordinate of the layer in tiles. Defaults to 0 and can no longer be changed in Tiled Qt. (Except ImageLayer) */
  @:optional var x:Float;
  /** The y coordinate of the layer in tiles. Defaults to 0 and can no longer be changed in Tiled Qt. (Except ImageLayer) */
  @:optional var y:Float;
  /** The width of the layer in tiles. Traditionally required, but as of Tiled Qt always the same as the map width. */
  @:optional var width:Int;
  /** The height of the layer in tiles. Traditionally required, but as of Tiled Qt always the same as the map height. */
  @:optional var height:Int;
  /** The opacity of the layer as a value from 0 to 1. Defaults to 1. */
  @:optional var opacity:Float;
  /** Whether the layer is shown (1) or hidden (0). Defaults to 1. */
  @:optional var visible:Bool;
  
  @:optional var properties:Map<String, String>;
}

/** A layer consisting of a single image. */
typedef TmxImageLayer =
{
  >TmxBaseLayer,
  
  @:optional var image:TmxImage;
}

typedef TmxTileLayer =
{
  >TmxBaseLayer,
  
  @:optional var data:TmxData;
}

/** Encoding of the data. */
enum TmxDataEncoding
{
  /** No encoding, data given in raw. */
  None;
  /** Base64-encoded data. */
  Base64;
  /** Comma-separated-values data. Can be applied only for tile data. */
  CSV;
}

/** Compression type for data. */
enum TmxDataCompression
{
  /** No compression. */
  None;
  /** GZip compression. Currently not supported. */
  GZip;
  /** ZLib compression. */
  ZLib;
}

/**
 * When no encoding or compression is given, the tiles are stored as individual XML tile elements.
 * Next to that, the easiest format to parse is the "csv" (comma separated values) format.
 * 
 * The base64-encoded and optionally compressed layer data is somewhat more complicated to parse.
 * First you need to base64-decode it, then you may need to decompress it. Now you have an array of bytes,
 * which should be interpreted as an array of unsigned 32-bit integers using little-endian byte ordering.
 * 
 * Whatever format you choose for your layer data, you will always end up with so called "global tile IDs" (gids).
 * They are global, since they may refer to a tile from any of the tilesets used by the map.
 * In order to find out from which tileset the tile is you need to find the tileset with the highest
 * firstgid that is still lower or equal than the gid. The tilesets are always stored with increasing firstgids.
 */
typedef TmxData =
{
  /** The encoding used to encode the tile layer data. When used, it can be "base64" and "csv" at the moment. */
  @:optional var encoding:TmxDataEncoding;
  /** The compression used to compress the tile layer data. Tiled Qt supports "gzip" and "zlib". Optional */
  @:optional var compression:TmxDataCompression;
  /** Decoded tile data */
  @:optional var tiles:Array<TmxTile>;
  /** Raw data. Exists for non-tile-layer data objects. */
  @:optional var data:Bytes;
}

/** Single tile in tile layer. */
typedef TmxTile =
{
  /** Global ID of tile. */
  var gid:Int;
  /** Is tile flipped horizontally? Default: false */
  @:optional var flippedHorizontally:Bool;
  /** Is tile flipped vertically? Default: false */
  @:optional var flippedVertically:Bool;
  /** Is tile flipped diagonally? Default: false */
  @:optional var flippedDiagonally:Bool;
}

/** Layer representing a group of objects. */
typedef TmxObjectGroup =
{
  >TmxBaseLayer,
  /** List of all objects. */
  @:optional var objects:Array<TmxObject>;
}

/** Utility for x/y object. Used for Polygon and Polyline object types.*/
typedef TmxPoint =
{
  var x:Float;
  var y:Float;
}

/**
 * Type of the object.
 */
enum TmxObjectType
{
  /** Standart rectangle. Use x/y/width/height to determine it's size and position. */
  Rectangle;
  /** Tile-object, placed on x/y position. */
  Tile(gid:Int);
  /** Ellipse. Fills area in x/y/w/h. */
  Ellipse;
  /** Enclosed polygon determined by points with origin of object x/y. */
  Polygon(points:Array<TmxPoint>);
  /** Polyline determined by points with origin of object x/y. */
  Polyline(points:Array<TmxPoint>);
}

typedef TmxObject =
{
  /** Id of the object. Each object that is placed on map gets unique id. And even if object was deleted no one gets it's id again. Can not be changed in Tiled Qt. */
  var id:Int;
  /** The name of the object. An arbitrary string. */
  @:optional var name:String;
  /** The type of the object. An arbitrary string. */
  @:optional var type:String;
  /** The x coordinate of the object in pixels. */
  var x:Float;
  /** The y coordinate of the object in pixels. */
  var y:Float;
  /** The width of the object in pixels (defaults to 0). */
  @:optional var width:Float;
  /** The height of the object in pixels (defaults to 0). */
  @:optional var height:Float;
  /** The rotation of the object in degrees clockwise (defaults to 0). (Since 0.11/git) */
  @:optional var rotation:Float;
  /** Whether the object is shown (1) or hidden (0). Defaults to 1. (since 0.9.0) */
  @:optional var visible:Bool;
  /** Helper type to easily detect what exactly is that object. */
  var objectType:TmxObjectType;
  /** Object properties. */
  @:optional var properties:Map<String, String>;
  /** Is tile flipped horizontally? Default: false */
  @:optional var flippedHorizontally:Bool;
  /** Is tile flipped vertically? Default: false */
  @:optional var flippedVertically:Bool;
}
