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
  /** Since 0.11 */
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
  Unknown(value:String);
}

enum TmxStaggerAxis
{
  AxisX;
  AxisY;
  Unknown(value:String);
}

/** General .tmx map file */
@:structInit
class TmxMap
{
  /** The TMX format version, generally 1.0. */
  public var version:String;
  /** Map orientation. */
  public var orientation:TmxOrientation;
  /** The map width in tiles. */
  public var width:Int;
  /** The map height in tiles. */
  public var height:Int;
  /**
   * The width of a tile.
   * 
   * The tilewidth and tileheight properties determine the general grid size of the map.  
   * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
   * */
  public var tileWidth:Int;
  /**
   * The height of a tile.
   * 
   * The tilewidth and tileheight properties determine the general grid size of the map.  
   * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
   */
  public var tileHeight:Int;
  /** The background color of the map. Since 0.9, optional. */
  @:optional public var backgroundColor:Int;
  /** The order in which tiles on tile layers are rendered. Since 0.10, but only for orthogonal orientation. */
  @:optional public var renderOrder:TmxRenderOrder;
  /** For staggered and hexagonal maps, determines whether the "even" or "odd" indexes along the staggered axis are shifted. Since 0.11 */
  @:optional public var staggerIndex:TmxStaggerIndex;
  /**
   * For staggered and hexagonal maps, determines which axis (x or y) is staggered. (since 0.11);
   * Ex staggerDirection.
   */
  @:optional public var staggerAxis:TmxStaggerAxis;
  /** Only for hexagonal maps. Determines the width or height (depending on the staggered axis) of the tile's edge, in pixels. Since 0.11 */
  @:optional public var hexSideLength:Int;
  
  /** Stores the next available ID for new objects. This number is stored to prevent reuse of the same ID after objects have been removed. (since 0.11) */
  @:optional public var nextObjectId:Int;
  
  /** Properties of the map */
  @:optional public var properties:TmxProperties;// Map<String, String>;
  
  /** Tilesets used in map */
  public var tilesets:Array<TmxTileset>;
  /** Array of all layers in map. Tile layers, object groups and image layers.*/
  public var layers:Array<TmxLayer>;
  /** Is that map infinite? */
  public var infinite:Bool;
}

/**
 * Tileset  
 * TSX files does not contains firstGID and source.  
 * TMX Tilesets can be both full tilesets or point to TSX file. In that case it contains only firstGID and source.  
 * You can merge TSX file TMX Tileset into one by using `new Reader(tsxXML).readTSX(tmxTileset);`.  
 * Since Tiled 0.15, image collection tilesets do not necessarily number their tiles consecutively since gaps can occur when removing tiles.
 */
@:structInit
class TmxTileset
{
  /** The first global tile ID of this tileset (this global ID maps to the first tile in this tileset). */
  @:optional public var firstGID:Null<Int>;
  /** If this tileset is stored in an external TSX (Tile Set XML) file, this attribute refers to that file. That TSX file has the same structure as the <tileset> element described here. (There is the firstgid attribute missing and this source attribute is also not there. These two attributes are kept in the TMX map, since they are map specific.) */
  @:optional public var source:String;
  /** The name of this tileset. */
  @:optional public var name:String;
  /** The (maximum) width of the tiles in this tileset. */
  @:optional public var tileWidth:Null<Int>;
  /** The (maximum) height of the tiles in this tileset. */
  @:optional public var tileHeight:Null<Int>;
  /** The spacing in pixels between the tiles in this tileset (applies to the tileset image). */
  @:optional public var spacing:Null<Int>;
  /** The margin around the tiles in this tileset (applies to the tileset image). */
  @:optional public var margin:Null<Int>;
  
  /** The number of tiles in this tileset (since 0.13) */
  @:optional public var tileCount:Int;
  /** The number of tile columns in the tileset. For image collection tilesets it is editable and is used when displaying the tileset. (since 0.15) */
  @:optional public var columns:Int;
  
  /** This element is used to specify an offset in pixels, to be applied when drawing a tile from the related tileset. When not present, no offset is applied. Since 0.8 */
  @:optional public var tileOffset:TmxTileOffset;
  /** Since 0.8 */
  @:optional public var properties:TmxProperties;// Map<String, String>;
  /**
   * As of the current version of Tiled Qt, each tileset has a single image associated with it,  
   * which is cut into smaller tiles based on the attributes defined on the tileset element.  
   * Later versions may add support for adding multiple images to a single tileset, as is possible in Tiled Java.
   */
  @:optional public var image:TmxImage;
  /** Terrain type defines. Since 0.9 */
  @:optional public var terrainTypes:Array<TmxTerrain>;
  /** Extended tiles data.  */
  @:optional public var tiles:Array<TmxTilesetTile>;
  
  /** Since 1.0 */
  @:optional public var grid:TmxTilesetGrid;
  
  /** Since 1.1 */
  @:optional public var wangSets:Array<TmxWangSet>;
}

/** This element is only used in case of isometric orientation, and determines how tile overlays for terrain and collision information are rendered. */
@:structInit
class TmxTilesetGrid
{
  /** Orientation of the grid for the tiles in this tileset (orthogonal or isometric) */
  public var orientation:TmxOrientation;
  /* Width of a grid cell */
  public var width:Int;
  /* Height of a grid cell */
  public var height:Int;
}

/** This element is used to specify an offset in pixels, to be applied when drawing a tile from the related tileset. When not present, no offset is applied. */
@:structInit
class TmxTileOffset
{
  /** Horizontal offset in pixels */
  public var x:Int;
  /** Vertical offset in pixels (positive is down) */
  public var y:Int;
}

/** Defines a list of corner colors and a list of edge colors, and any number of Wang tiles using these colors. */
@:structInit
class TmxWangSet
{
  /** The name of the Wang set. */
  public var name:String;
  /** The tile ID of the tile representing this Wang set. */
  public var tile:Int;
  
  /** A color that can be used to define the corner of a Wang tile. */
  public var corners:Array<TmxWangSetColor>;
  /** A color that can be used to define the edge of a Wang tile. */
  public var edges:Array<TmxWangSetColor>;
  /** Defines a Wang tile, by referring to a tile in the tileset and associating it with a certain Wang ID. */
  public var tiles:Array<TmxWangSetTile>;
}

/** A color that can be used to define the corner or an edge of a Wang tile. */
@:structInit
class TmxWangSetColor
{
  /** The name of this color. */
  public var name:String;
  /** The color in #RRGGBB format (example: #c17d11). */
  public var color:Int;
  /** The tile ID of the tile representing this color. */
  public var tile:Int;
  /** The relative probability that this color is chosen over others in case of multiple options. */
  public var probability:Float;
}

/** Defines a Wang tile, by referring to a tile in the tileset and associating it with a certain Wang ID. */
@:structInit
class TmxWangSetTile
{
  /** The tile ID. */
  public var tileID:Int;
  /**
   * The Wang ID, which is a 32-bit unsigned integer stored in the format 0xCECECECE
   * (where each C is a corner color and each E is an edge color, from right to left clockwise, starting with the top edge)
   */
  public var wangID:Int; // TODO: Abstract
}

/**
 * As of the current version of Tiled Qt, each tileset has a single image associated with it,  
 * which is cut into smaller tiles based on the attributes defined on the tileset element.  
 * Later versions may add support for adding multiple images to a single tileset, as is possible in Tiled Java.
 */
@:structInit
class TmxImage
{
  /** Used for embedded images, in combination with a data child element. Valid values are file extensions like png, gif, jpg, bmp, etc. (since 0.9.0) */
  @:optional public var format:String;
  /** Used by some versions of Tiled Java. Deprecated and unsupported by Tiled Qt. */
  @:optional public var id:String;
  /** The reference to the tileset image file (Tiled supports most common image formats). */
  public var source:String;
  /**
   * Defines a specific color that is treated as transparent (example value: "#FF00FF" for magenta). 
   * Up until Tiled 0.10 (upd: 0.12), this value is written out without a # but this is planned to change.
   */
  @:optional public var transparent:Null<Int>;
  /** The image width in pixels (optional, used for tile index correction when the image changes) */
  @:optional public var width:Null<Int>;
  /** The image height in pixels (optional) */
  @:optional public var height:Null<Int>;
  /** Since 0.9 */
  @:optional public var data:TmxData;
}

@:structInit
class TmxTerrain
{
  /** The name of the terrain type. */
  public var name:String;
  /** The local tile-id of the tile that represents the terrain visually. */
  public var tile:Int;
  
  @:optional public var properties:TmxProperties;// Map<String, String>;
}

@:structInit
class TmxTilesetTile
{
  /** The local tile ID within its tileset. */
  public var id:Int;
  
  @:optional public var type:String;
  /**
   * Defines the terrain type of each corner of the tile,
   * given as comma-separated indexes in the terrain types array in the order 
   * top-left, top-right, bottom-left, bottom-right. Leaving out a value means
   * that corner has no terrain. (optional) (since 0.9.0)
   */
  @:optional public var terrain:String;
  /**
   * A percentage indicating the probability that this tile is chosen when it
   * competes with others while editing with the terrain tool. (optional) (since 0.9.0)
   */
  @:optional public var probability:Float;
  
  @:optional public var properties:TmxProperties;// Map<String, String>;
  /**
   * Since 0.9
   */
  @:optional public var image:TmxImage;
  /**
   * Since 0.10.
   * This group represents collision of tile and never contains Tile object type.
   */
  @:optional public var objectGroup:TmxObjectGroup;
  /**
   * Since 0.10.
   * Present, if tile does not static and contains animation.  
   * Contains a list of animation frames.  
   * As of Tiled 0.10, each tile can have exactly one animation associated with it. In the future, there could be support for multiple named animations on a tile.
   */
  @:optional public var animation:Array<TmxTilesetTileFrame>;
}

/**
 * Animation frame of a single tile in tileset.
 */
@:structInit
class TmxTilesetTileFrame
{
  /** The local ID of a tile within the parent tileset. */
  public var tileId:Int;
  /** How long (in milliseconds) this frame should be displayed before advancing to the next frame. */
  public var duration:Int;
}

enum TmxLayer
{
  LTileLayer(layer:TmxTileLayer);
  LObjectGroup(group:TmxObjectGroup);
  LImageLayer(layer:TmxImageLayer);
  LGroup(group:TmxGroup);
}

/**
 * A group layer, used to organize the layers of the map in a hierarchy. 
 * Its attributes offsetx, offsety, opacity and visible recursively affect child layers.
 */
@:structInit
class TmxGroup
{
  /** The name of the group layer. */
  public var name:String;
  /** Rendering offset of the group layer in pixels. Defaults to 0. */
  public var offsetX:Int;
  /** Rendering offset of the group layer in pixels. Defaults to 0. */
  public var offsetY:Int;
  /** The opacity of the layer as a value from 0 to 1. Defaults to 1. */
  public var opacity:Float;
  /** Whether the layer is shown (1) or hidden (0). Defaults to 1. */
  public var visible:Bool;
  
  public var properties:TmxProperties;
  
  public var layers:Array<TmxLayer>;
}

class TmxBaseLayer
{
  /** The name of the layer. */
  public var name:String;
  /** The x coordinate of the layer in tiles. Defaults to 0 and can no longer be changed in Tiled Qt. (Except ImageLayer) */
  public var x:Null<Float>;
  /** The y coordinate of the layer in tiles. Defaults to 0 and can no longer be changed in Tiled Qt. (Except ImageLayer) */
  public var y:Null<Float>;
  /** The width of the layer in tiles. Traditionally required, but as of Tiled Qt always the same as the map width. */
  public var width:Null<Int>;
  /** The height of the layer in tiles. Traditionally required, but as of Tiled Qt always the same as the map height. */
  public var height:Null<Int>;
  /** The opacity of the layer as a value from 0 to 1. Defaults to 1. */
  public var opacity:Null<Float>;
  /** Whether the layer is shown (1) or hidden (0). Defaults to 1. */
  public var visible:Null<Bool>;
  /** Rendering offset for this layer in pixels. Defaults to 0. (since 0.14) */
  public var offsetX:Null<Int>;
  /** Rendering offset for this layer in pixels. Defaults to 0. (since 0.14) */
  public var offsetY:Null<Int>;
  
  public var properties:TmxProperties;// Map<String, String>;
  
  public function new(name:String, x:Null<Float>, y:Null<Float>, offsetX:Null<Int>, offsetY:Null<Int>,
    width:Null<Int>, height:Null<Int>, opacity:Null<Float>, visible:Bool, properties:TmxProperties)
  {
    this.name = name;
    this.x = x;
    this.y = y;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.width = width;
    this.height = height;
    this.opacity = opacity;
    this.visible = visible;
    this.properties = properties;
  }
  
}

/**
 * A layer consisting of a single image.
 * Since 0.15 `x` and `y` position of layer is defined via `offsetX` and `offsetY`.
 */
 
class TmxImageLayer extends TmxBaseLayer
{
  @:optional public var image:TmxImage;
  
  public function new(image:TmxImage,
    name:String, x:Null<Float>, y:Null<Float>, offsetX:Null<Int>, offsetY:Null<Int>,
    width:Null<Int>, height:Null<Int>, opacity:Null<Float>, visible:Bool, properties:TmxProperties)
  {
    super(name, x, y, offsetX, offsetY, width, height, opacity, visible, properties);
    this.image = image;
  }
}

@:structInit
class TmxTileLayer extends TmxBaseLayer
{
  @:optional public var data:TmxData;
  
  public function new(data:TmxData,
    name:String, x:Null<Float>, y:Null<Float>, offsetX:Null<Int>, offsetY:Null<Int>,
    width:Null<Int>, height:Null<Int>, opacity:Null<Float>, visible:Bool, properties:TmxProperties)
  {
    super(name, x, y, offsetX, offsetY, width, height, opacity, visible, properties);
    this.data = data;
  }
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
  /** Unknown encoding */
  Unknown(value:String);
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
  /** Unknown compression */
  Unknown(value:String);
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
@:structInit
class TmxData
{
  /** The encoding used to encode the tile layer data. When used, it can be "base64" and "csv" at the moment. */
  @:optional public var encoding:TmxDataEncoding;
  /** The compression used to compress the tile layer data. Tiled Qt supports "gzip" and "zlib". Optional */
  @:optional public var compression:TmxDataCompression;
  /** Decoded tile data */
  @:optional public var tiles:Array<TmxTile>;
  /** Infinite maps chunk data */
  @:optional public var chunks:Array<TmxChunk>;
  /** Raw data. Exists for non-tile-layer data objects. */
  @:optional public var data:Bytes;
}

/**
 * This is currently added only for infinite maps. The contents of a chunk element is same as that of 
 * the data element, except it stores the data of the area specified in the attributes. */
@:structInit
class TmxChunk
{
  /** The x coordinate of the chunk in tiles. */
  public var x:Int;
  /** The y coordinate of the chunk in tiles. */
  public var y:Int;
  /** The width of the chunk in tiles. */
  public var width:Int;
  /** The height of the chunk in tiles. */
  public var height:Int;
  
  /** Decoded tile data */
  public var tiles:Array<TmxTile>;
}

/** Single tile in tile layer. */
@:structInit
class TmxTile
{
  /** Global ID of tile. */
  public var gid:Int;
  /** Is tile flipped horizontally? Default: false */
  @:optional public var flippedHorizontally:Bool;
  /** Is tile flipped vertically? Default: false */
  @:optional public var flippedVertically:Bool;
  /** Is tile flipped diagonally? Default: false */
  @:optional public var flippedDiagonally:Bool;
}

/** Whether the objects are drawn according to the order of appearance ("index") or sorted by their y-coordinate ("topdown"). Defaults to "topdown". */
enum TmxObjectGroupDrawOrder
{
  /** Objects should be drawn according to it's position in `objects` array. */
  Index;
  /** Objects should be drawn according to their Y-coordinate. Default value. */
  Topdown;
  /** Unknown draw order. */
  Unknown(value:String);
}

/** Layer representing a group of objects. */

class TmxObjectGroup extends TmxBaseLayer
{
  /** The color used to display the objects in this group. */
  public var color:Null<Int>;
  /** Whether the objects are drawn according to the order of appearance ("index") or sorted by their y-coordinate ("topdown"). Defaults to "topdown". */
  public var drawOrder:TmxObjectGroupDrawOrder;
  /** List of all objects. */
  public var objects:Array<TmxObject>;
  
  public function new(drawOrder:TmxObjectGroupDrawOrder, objects:Array<TmxObject>, color:Null<Int>, 
    name:String, x:Null<Float>, y:Null<Float>, offsetX:Null<Int>, offsetY:Null<Int>,
    width:Null<Int>, height:Null<Int>, opacity:Null<Float>, visible:Bool, properties:TmxProperties)
  {
    super(name, x, y, offsetX, offsetY, width, height, opacity, visible, properties);
    this.color = color;
    this.drawOrder = drawOrder;
    this.objects = objects;
  }
  
}

/** Utility for x/y object. Used for Polygon and Polyline object types.*/
@:structInit
class TmxPoint
{
  public var x:Float;
  public var y:Float;
}

/**
 * Type of the object.
 */
enum TmxObjectType
{
  /** Standart rectangle. Use x/y/width/height to determine it's size and position. */
  OTRectangle;
  /** Tile-object, placed on x/y position. */
  OTTile(gid:Int);
  /** Ellipse. Fills area in x/y/w/h. */
  OTEllipse;
  /** Enclosed polygon determined by points with origin of object x/y. */
  OTPolygon(points:Array<TmxPoint>);
  /** Used to mark an object as a text object. Contains the actual text as character data. */
  OTText(text:TmxText);
  /** Polyline determined by points with origin of object x/y. */
  OTPolyline(points:Array<TmxPoint>);
}

@:structInit
class TmxObject
{
  /** Id of the object. Each object that is placed on map gets unique id. And even if object was deleted no one gets it's id again. Can not be changed in Tiled Qt. */
  public var id:Int;
  /** The name of the object. An arbitrary string. */
  @:optional public var name:String;
  /** The type of the object. An arbitrary string. */
  @:optional public var type:String;
  /** The x coordinate of the object in pixels. */
  public var x:Float;
  /** The y coordinate of the object in pixels. */
  public var y:Float;
  /** The width of the object in pixels (defaults to 0). */
  @:optional public var width:Float;
  /** The height of the object in pixels (defaults to 0). */
  @:optional public var height:Float;
  /** The rotation of the object in degrees clockwise (defaults to 0). (Since 0.10) */
  @:optional public var rotation:Float;
  /** Whether the object is shown (1) or hidden (0). Defaults to 1. (since 0.9.0) */
  @:optional public var visible:Bool;
  /** Helper type to easily detect what exactly is that object. */
  public var objectType:TmxObjectType;
  /** Object properties. */
  @:optional public var properties:TmxProperties;// Map<String, String>;
  
  /** Is tile flipped horizontally? Default: false */
  @:optional public var flippedHorizontally:Bool;
  /** Is tile flipped vertically? Default: false */
  @:optional public var flippedVertically:Bool;
  
  /** A reference to a template file (optional). */
  @:optional public var template:String;
}

/** Used to mark an object as a text object. Contains the actual text as character data. */
@:structInit
class TmxText
{
  /** The font family used (default: “sans-serif”) */
  public var fontFamily:String;
  /** The size of the font in pixels (not using points, because other sizes in the TMX format are also using pixels) (default: 16) */
  public var pixelSize:Int; // TODO: Check if int or float
  /** Whether word wrapping is enabled (1) or disabled (0). Defaults to 0. */
  public var wrap:Bool;
  /** Color of the text in #AARRGGBB or #RRGGBB format (default: #000000) */
  public var color:Int;
  /** Whether the font is bold (1) or not (0). Defaults to 0. */
  public var bold:Bool;
  /** Whether the font is italic (1) or not (0). Defaults to 0. */
  public var italic:Bool;
  /** Whether a line should be drawn below the text (1) or not (0). Defaults to 0. */
  public var underline:Bool;
  /** Whether a line should be drawn through the text (1) or not (0). Defaults to 0. */
  public var strikeout:Bool;
  /** Whether kerning should be used while rendering the text (1) or not (0). Default to 1. */
  public var kerning:Bool;
  /** Horizontal alignment of the text within the object (left (default), center or right) */
  public var halign:TmxHAlign;
  /** Vertical alignment of the text within the object (top (default), center or bottom) */
  public var valign:TmxVAlign;
  /** Actual text of object */
  public var text:String;
}

@:enum
abstract TmxHAlign(String) from String to String
{
  var Left = "left";
  var Center = "center";
  var Right = "right";
}

@:enum
abstract TmxVAlign(String) from String to String
{
  var Top = "top";
  var Center = "center";
  var Bottom = "bottom";
}

enum TmxPropertyType
{
  PTString;
  PTInt;
  PTBool;
  PTFloat;
  /** Since 0.17 */
  PTFile; // Is just a String
  PTColor; // Is just an Int
}

@:forward
abstract TmxProperties(ImplTmxProperties)
{
  
  public inline function new() this = new ImplTmxProperties();
  
  @:arrayAccess
  private inline function _get(v:String):String return this.get(v);
  
  @:arrayAccess
  private inline function _set(k:String, v:String):String
  {
    this.setString(k, v);
    return v;
  }
  
}

private class ImplTmxProperties
{
  private var names:Array<String>;
  private var types:Array<TmxPropertyType>;
  private var strings:Array<String>; // file
  private var cache:Array<Null<Int>>;
  private var ints:Array<Int>; // color
  private var floats:Array<Float>;
  //private var bools:Array<Bool>;
  
  public inline function propertyCount():Int return names.length;
  
  public function new()
  {
    this.names = new Array();
    this.types = new Array();
    this.strings = new Array();
    this.cache = new Array();
    this.ints = new Array();
    this.floats = new Array();
    //this.bools = new Array();
  }
  
  public function exists(name:String):Bool
  {
    return names.indexOf(name) != -1;
  }
  
  public function existsType(name:String, type:TmxPropertyType):Bool
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return false;
    return types[idx] == type;
  }
  
  @:noCompletion
  public function setRaw(name:String, value:String, type:TmxPropertyType):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      names.push(name);
      strings.push(value);
      types.push(type);
    }
    else
    {
      strings[idx] = value;
      types[idx] = type;
      cache[idx] = null;
    }
  }
  
  public function setString(name:String, value:String):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      names.push(name);
      types.push(PTString);
      strings.push(value);
    }
    else
    {
      types[idx] = PTString;
      cache[idx] = null;
      strings[idx] = value;
    }
  }
  
  public function setFile(name:String, value:String):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      names.push(name);
      types.push(PTFile);
      strings.push(value);
    }
    else
    {
      types[idx] = PTFile;
      strings[idx] = value;
      cache[idx] = null;
    }
  }
  
  public function setInt(name:String, value:Int):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      idx = names.push(name) - 1;
      types.push(PTInt);
      strings.push(Std.string(value));
      cache[idx] = ints.push(value) - 1;
    }
    else
    {
      var oldType:TmxPropertyType = types[idx];
      types[idx] = PTInt;
      strings[idx] = Std.string(value);
      var cached:Null<Int> = cache[idx];
      if ((oldType == PTInt || oldType == PTColor) && cached != null)
      {
        ints[cached] = value;
      }
      else
      {
        cache[idx] = ints.push(value) - 1;
      }
    }
  }
  
  public function setColor(name:String, value:Int):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      idx = names.push(name) - 1;
      types.push(PTColor);
      strings.push(Std.string(value));
      cache[idx] = ints.push(value) - 1;
    }
    else
    {
      var oldType:TmxPropertyType = types[idx];
      types[idx] = PTColor;
      strings[idx] = Std.string(value);
      var cached:Null<Int> = cache[idx];
      if ((oldType == PTColor || oldType == PTInt) && cached != null)
      {
        ints[cached] = value;
      }
      else
      {
        cache[idx] = ints.push(value) - 1;
      }
    }
  }
  
  public function setFloat(name:String, value:Float):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      var idx:Int = names.push(name) - 1;
      types.push(PTFloat);
      strings.push(Std.string(value));
      cache[idx] = floats.push(value) - 1;
    }
    else
    {
      var oldType:TmxPropertyType = types[idx];
      types[idx] = PTFloat;
      strings[idx] = Std.string(value);
      var cached:Null<Int> = cache[idx];
      if (oldType == PTFloat && cached != null)
      {
        floats[cached] = value;
      }
      else
      {
        cache[idx] = floats.push(value) - 1;
      }
    }
  }
  
  public function setBool(name:String, value:Bool):Void
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1)
    {
      names.push(name);
      types.push(PTBool);
      strings.push(value ? "true" : "false");
    }
    else
    {
      types[idx] = PTBool;
      strings[idx] = value ? "true" : "false";
      cache[idx] = null;
    }
  }
  
  public function getType(name:String):TmxPropertyType
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return null;
    return types[idx];
  }
  
  public inline function get(name:String):String return getString(name);
  
  public inline function keys():Iterator<String> return names.iterator();
  
  public function getString(name:String):String
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return null;
    return strings[idx];
  }
  
  public inline function getFile(name:String):String return getString(name);
  
  public function getInt(name:String):Null<Int>
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return null;
    var type:TmxPropertyType = types[idx];
    if (type != TmxPropertyType.PTInt || type != TmxPropertyType.PTColor) return null;
    
    var cached:Null<Int> = cache[idx];
    if (cached == null)
    {
      cached = Std.parseInt(strings[idx]);
      cache[idx] = ints.push(cached) - 1;
      return cached;
    }
    return ints[cached];
  }
  
  public inline function getColor(name:String):Null<Int> return getInt(name);
  
  public function getFloat(name:String):Float
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return Math.NaN;
    var type:TmxPropertyType = types[idx];
    // TODO: Optimize
    if (type == TmxPropertyType.PTInt || type == TmxPropertyType.PTColor) return getInt(name);
    if (type != TmxPropertyType.PTFloat) return Math.NaN;
    
    var cached:Null<Int> = cache[idx];
    if (cached == null)
    {
      var fval:Float = Std.parseFloat(strings[idx]);
      cache[idx] = floats.push(fval) - 1;
      return fval;
    }
    return floats[cached];
  }
  
  public function getBool(name:String):Bool
  {
    var idx:Int = names.indexOf(name);
    if (idx == -1) return false;
    return strings[idx] == "true";
    //var type:TmxPropertyType = types[idx];
    //if (type != TmxPropertyType.PTBool) return false;
    // Eh
  }
  
  public function propagateTo(other:TmxProperties, _override:Bool = false):Void
  {
    var i:Int = 0;
    while (i < names.length)
    {
      if (other.names.indexOf(names[i]) == -1 || _override)
      {
        other.setRaw(names[i], strings[i], types[i]);
      }
      i++;
    }
  }
  
}

// TODO: TmxGroup

@:structInit
class TmxObjectTemplate
{
  public var tileset:TmxTileset;
  public var object:TmxObject;
}

@:structInit
class TmxObjectTypeTemplate
{
  public var name:String;
  public var color:Int;
  public var properties:Array<TmxObjectTypeProperty>;
}

@:structInit
class TmxObjectTypeProperty
{
  public var name:String;
  public var type:TmxPropertyType;
  @:optional public var defaultValue:String;
}