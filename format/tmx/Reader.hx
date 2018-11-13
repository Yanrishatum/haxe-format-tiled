package format.tmx;
import format.tmx.Data;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.StringInput;
#if (haxe_ver >= 4)
import haxe.xml.Access as Fast;
#else
import haxe.xml.Fast;
#end
import haxe.zip.InflateImpl;
import haxe.zip.Uncompress;

/**
 * ...
 * @author Yanrishatum
 */
class Reader
{
  private var customUncompressors:Map<String, String->Bytes>;
  private var customEncoders:Map<String, Bytes->String->Array<TmxTile>>;
  
  private var width:Int;
  private var height:Int;
  
  /** For seamless TSX resolving during initial parsing. Should return corresponding TSX. Caching should be done from outside. */
  public var resolveTSX:String->TmxTileset;
  /** For seamless Template resolving during initial parsing. */
  public var resolveTemplate:String->TmxObjectTemplate;
  /** For seamless Type Template resolving during initial parsing. */
  public var resolveTypeTemplate:String->TmxObjectTypeTemplate;
  
  public function new() 
  {
    
  }
  
  /**
   * Reads TMX file.
   * @return
   */
  public function read(xml:Xml):TmxMap
  {
    var map:Fast = new Fast(xml).node.map;
    
    var properties:TmxProperties = resolveProperties(map);
    var tilesets:Array<TmxTileset> = new Array();
    var layers:Array<TmxLayer> = new Array();
    
    for (element in map.elements)
    {
      switch (element.name)
      {
        case "tileset": tilesets.push(resolveTileset(element, null));
        case "layer": layers.push(TmxLayer.LTileLayer(resolveTileLayer(element)));
        case "objectgroup": layers.push(TmxLayer.LObjectGroup(resolveObjectGroup(element)));
        case "imagelayer": layers.push(TmxLayer.LImageLayer(resolveImageLayer(element)));
        case "group": layers.push(TmxLayer.LGroup(resolveGroup(element)));
      }
    }
    
    this.width = Std.parseInt(map.att.width);
    this.height = Std.parseInt(map.att.height);
    
    return {
      version: map.att.version,
      orientation: resolveOrientation(map.att.orientation),
      width: width,
      height: height,
      tileWidth: Std.parseInt(map.att.tilewidth),
      tileHeight: Std.parseInt(map.att.tileheight),
      backgroundColor: map.has.backgroundcolor ? resolveColor(map.att.backgroundcolor) : 0,
      renderOrder: map.has.renderorder ? resolveRenderOrder(map.att.renderorder) : TmxRenderOrder.RightDown,
      properties: properties,
      tilesets: tilesets,
      layers: layers,
      staggerIndex: map.has.staggerindex ? resolveStaggerIndex(map.att.staggerindex) : null,
      staggerAxis: map.has.staggeraxis ? resolveStaggerAxis(map.att.staggeraxis) : null,
      hexSideLength: map.has.hexsidelength ? Std.parseInt(map.att.hexsidelength) : 0,
      nextObjectId: map.has.nextobjectid ? Std.parseInt(map.att.nextobjectid) : 0,
      infinite: map.has.infinite ? map.att.infinite == "1" : false
    };
  }
  
  /**
   * Reads TSX file.
   * @param root Root Tileset into which read TSX data.
   * @return Resulting TmxTileset. If `root` is null - returns new TmxTileset object, otherwise `root` is returned.
   */
  public inline function readTSX(xml:Xml, root:TmxTileset = null):TmxTileset
  {
    return resolveTileset(new Fast(xml).node.tileset, root);
  }
  
  /**
   * Reads objecttypes.xml file.
   * @param root Optional root TMX file to propagate those types into. It uses `Tools.propagateObjectTypes` function with default propagation rules.
   * @return Map with object type templates. Always pass null, if using during resolveTypeTemplate
   */
  public function readObjectTypes(xml:Xml, root:TmxMap = null):Map<String, TmxObjectTypeTemplate>
  {
    var result:Map<String, TmxObjectTypeTemplate> = new Map();
    var f:Fast = new Fast(xml);
    if (!f.hasNode.objecttypes) return result;
    for (type in f.node.objecttypes.nodes.objecttype)
    {
      var props:Array<TmxObjectTypeProperty> = new Array();
      for (prop in type.nodes.property)
      {
        var ptype:TmxPropertyType = 
        if (prop.has.type)
        {
          switch (prop.att.type)
          {
            case "string": PTString;
            case "int": PTInt;
            case "float": PTFloat;
            case "color": PTColor;
            case "file": PTFile;
            case "bool": PTBool;
            default: PTString;
          }
        }
        else PTString;
        props.push( {
          name: prop.att.name,
          type: ptype,
          defaultValue: prop.has.resolve("default") ? prop.att.resolve("default") : null
        });
      }
      result.set(type.att.name, {
        name: type.att.name,
        color: Std.parseInt("0x" + type.att.color.substr(1)),
        properties: props
      });
    }
    if (root != null) Tools.propagateObjectTypes(root, result);
    return result;
  }
  
  /**
     Reads TX file.
  **/
  public function readTemplate(xml:Xml):TmxObjectTemplate
  {
    var f:Fast = new Fast(xml);
    if (!f.hasNode.template) return null;
    var input:Fast = f.node.template;
    return {
      tileset: input.hasNode.tileset ? resolveTileset(input.node.tileset, null) : null,
      object: resolveObject(input.node.object)
    };
  }
  
  private function resolveGroup(input:Fast):TmxGroup
  {
    var layers:Array<TmxLayer> = new Array();
    
    for (element in input.elements)
    {
      switch (element.name)
      {
        case "layer": layers.push(TmxLayer.LTileLayer(resolveTileLayer(element)));
        case "objectgroup": layers.push(TmxLayer.LObjectGroup(resolveObjectGroup(element)));
        case "imagelayer": layers.push(TmxLayer.LImageLayer(resolveImageLayer(element)));
        case "group": layers.push(TmxLayer.LGroup(resolveGroup(element)));
      }
    }
    
    return {
      name: input.att.name,
      offsetX: input.has.offsetx ? Std.parseInt(input.att.offsetx) : 0,
      offsetY: input.has.offsety ? Std.parseInt(input.att.offsety) : 0,
      opacity: input.has.opacity ? Std.parseFloat(input.att.opacity) : 1,
      visible: input.has.visible ? input.att.visible == "1" : true,
      properties: resolveProperties(input),
      layers: layers
    };
  }
  
  private inline function resolveStaggerIndex(input:String):TmxStaggerIndex
  {
    switch (input)
    {
      case "even": return TmxStaggerIndex.Even;
      case "odd": return TmxStaggerIndex.Odd;
      default: return TmxStaggerIndex.Unknown(input);
    }
  }
  
  private inline function resolveStaggerAxis(input:String):TmxStaggerAxis
  {
    switch (input)
    {
      case "x": return TmxStaggerAxis.AxisX;
      case "y": return TmxStaggerAxis.AxisY;
      default: return TmxStaggerAxis.Unknown(input);
    }
  }
  
  private inline function resolveOrientation(input:String):TmxOrientation
  {
    switch (input)
    {
      case "orthogonal": return TmxOrientation.Orthogonal;
      case "hexagonal": return TmxOrientation.Hexagonal;
      case "isometric": return TmxOrientation.Isometric;
      case "staggered": return TmxOrientation.Staggered;
      default : return TmxOrientation.Unknown(input);
    }
  }
  
  private inline function resolveColor(input:String):Int
  {
    if (input.charCodeAt(0) == "#".code) return Std.parseInt("0x" + input.substr(1));
    else return Std.parseInt("0x" + input);
  }
  
  private inline function resolveRenderOrder(input:String):TmxRenderOrder
  {
    switch (input)
    {
      case "right-down": return TmxRenderOrder.RightDown;
      case "right-up": return TmxRenderOrder.RightUp;
      case "left-down": return TmxRenderOrder.LeftDown;
      case "left-up": return TmxRenderOrder.LeftUp;
      default : return TmxRenderOrder.Unknown(input);
    }
  }
  
  private inline function resolveTileset(input:Fast, root:TmxTileset):TmxTileset
  {
    var properties:TmxProperties = resolveProperties(input);
    var terrains:Array<TmxTerrain> = new Array();
    var hasTerrains:Bool = input.hasNode.terraintypes;
    var tiles:Array<TmxTilesetTile> = new Array();
    var hasTiles:Bool = input.hasNode.tile;
    var tileOffset:TmxTileOffset = null;
    var hasTileOffset:Bool = input.hasNode.tileoffset;
    var wangSets:Array<TmxWangSet> = new Array();
    var hasWangSets:Bool = input.hasNode.wangsets;
    var grid:TmxTilesetGrid = null;
    var hasGrid:Bool = input.hasNode.grid;
    
    if (hasTileOffset)
    {
      var node:Fast = input.node.tileoffset;
      tileOffset = { x:Std.parseInt(node.att.x), y:Std.parseInt(node.att.y) };
    }
    
    if (hasTerrains)
    {
      for (node in input.node.terraintypes.nodes.terrain)
      {
        terrains.push( { name:node.att.name, tile:Std.parseInt(node.att.tile), properties:resolveProperties(node) } );
      }
    }
    
    if (hasWangSets)
    {
      for (node in input.node.wangsets.nodes.wangset)
      {
        wangSets.push(resolveWangSet(node));
      }
    }
    
    if (hasGrid)
    {
      var gnode:Fast = input.node.grid;
      grid = {
        width: Std.parseInt(gnode.att.width),
        height: Std.parseInt(gnode.att.height),
        orientation: resolveOrientation(gnode.att.orientation)
      };
    }
    
    if (hasTiles)
    {
      for (node in input.nodes.tile)
      {
        var animation:Array<TmxTilesetTileFrame> = null;
        if (node.hasNode.animation)
        {
          animation = new Array();
          for (frameInfo in node.node.animation.nodes.frame)
          {
            animation.push( {
              tileId: Std.parseInt(frameInfo.att.tileid),
              duration: Std.parseInt(frameInfo.att.duration)
            });
          }
        }
        tiles.push( {
         id: Std.parseInt(node.att.id),
         terrain: node.has.terrain ? node.att.terrain : null,
         probability: node.has.probability ? Std.parseFloat(node.att.probability) : 0,
         properties: resolveProperties(node),
         image: node.hasNode.image ? resolveImage(node.node.image) : null,
         objectGroup: node.hasNode.objectgroup ? resolveObjectGroup(node.node.objectgroup) : null,
         animation: animation,
         type: node.has.type ? node.att.type : null
        });
      }
    }
    
    //if (root == null && input.has.source && resolveTSX != null)
    //{
      //root = resolveTSX(input.att.source);
      //root.source = input.att.source;
      //root.firstGID = input.has.firstgid ? Std.parseInt(input.att.firstgid) : null;
      //return root;
    //}
    
    if (root != null)
    {
      root.firstGID = input.has.firstgid ? Std.parseInt(input.att.firstgid) : root.firstGID;
      root.source = input.has.source ? input.att.source : root.source;
      root.name = input.has.name ? input.att.name : root.name;
      root.tileWidth = input.has.tilewidth ? Std.parseInt(input.att.tilewidth) : root.tileWidth;
      root.tileHeight = input.has.tileheight ? Std.parseInt(input.att.tileheight) : root.tileHeight;
      root.spacing = input.has.spacing ? Std.parseInt(input.att.spacing) : root.spacing;
      root.margin = input.has.margin ? Std.parseInt(input.att.margin) : root.margin;
      root.properties = input.hasNode.properties ? properties : root.properties;
      root.image = input.hasNode.image ? resolveImage(input.node.image) : root.image;
      root.tileCount = input.has.tilecount ? Std.parseInt(input.att.tilecount) : 0;
      root.columns = input.has.columns ? Std.parseInt(input.att.columns) : 0;
      if (hasTerrains) root.terrainTypes = terrains;
      if (hasTiles) root.tiles = tiles;
      if (hasTileOffset) root.tileOffset = tileOffset;
      if (hasWangSets) root.wangSets = wangSets;
      if (hasGrid) root.grid = grid;
      return root;
    }
    
    var tset:TmxTileset =
    {
      firstGID: input.has.firstgid ? Std.parseInt(input.att.firstgid) : null,
      source: input.has.source ? input.att.source : null,
      name: input.has.name ? input.att.name : null,
      tileWidth: input.has.tilewidth ? Std.parseInt(input.att.tilewidth) : 0,
      tileHeight: input.has.tileheight ? Std.parseInt(input.att.tileheight) : 0,
      spacing: input.has.spacing ? Std.parseInt(input.att.spacing) : 0,
      margin: input.has.margin ? Std.parseInt(input.att.margin) : 0,
      properties: properties,
      image: input.hasNode.image ? resolveImage(input.node.image) : null,
      tileCount: input.has.tilecount ? Std.parseInt(input.att.tilecount) : 0,
      columns: input.has.columns ? Std.parseInt(input.att.columns) : 0,
      terrainTypes: terrains,
      tiles: tiles,
      tileOffset: tileOffset,
      grid: grid,
      wangSets: wangSets
    };
    
    if (tset.source != null && resolveTSX != null)
    {
      var tsx:TmxTileset = resolveTSX(tset.source);
      Tools.applyTSX(tsx, tset);
    }
    
    return tset;
  }
  
  private function resolveWangSet(input:Fast):TmxWangSet
  {
    var corners:Array<TmxWangSetColor> = new Array();
    var edges:Array<TmxWangSetColor> = new Array();
    var tiles:Array<TmxWangSetTile> = new Array();
    
    for (node in input.nodes.wangcornercolor)
    {
      corners.push(resolveWangSetColor(node));
    }
    
    for (node in input.nodes.wangedgecolor)
    {
      edges.push(resolveWangSetColor(node));
    }
    
    for (node in input.nodes.wangtile)
    {
      tiles.push( {
        tileID: node.has.tileid ? Std.parseInt(node.att.tileid) : 0,
        wangID: node.has.wangid ? Std.parseInt(node.att.wangid) : 0
      });
    }
    
    return {
      name: input.has.name ? input.att.name : null,
      tile: input.has.tile ? Std.parseInt(input.att.tile) : 0,
      corners: corners,
      edges: edges,
      tiles: tiles
    };
    
  }
  
  private inline function resolveWangSetColor(input:Fast):TmxWangSetColor
  {
    return {
      name: input.has.name ? input.att.name : null,
      color: input.has.color ? resolveColor(input.att.color) : 0,
      tile: input.has.tile ? Std.parseInt(input.att.tile) : 0,
      probability: input.has.probability ? Std.parseFloat(input.att.probability) : 0
    };
  }
  
  private function resolveImage(input:Fast):TmxImage
  {
    return 
    {
      format: input.has.format ? input.att.format : "",
      id: input.has.id ? input.att.id : "",
      source: input.has.source ? input.att.source : "",
      transparent: input.has.transparent ? resolveColor(input.att.transparent) : null,
      width: input.has.width ? Std.parseInt(input.att.width) : null,
      height: input.has.height ? Std.parseInt(input.att.height) : null,
      data: input.hasNode.data ? resolveData(input.node.data, false) : null
    };
  }
  
  private inline static var FLIPPED_HORIZONTALLY_FLAG:Int = 0x80000000;
  private inline static var FLIPPED_VERTICALLY_FLAG:Int   = 0x40000000;
  private inline static var FLIPPED_DIAGONALLY_FLAG:Int   = 0x20000000;
  private inline static var FLAGS_MASK:Int = 0x1FFFFFFF;
  
  private function resolveData(input:Fast, isTileData:Bool = true):TmxData
  {
    var encoding:TmxDataEncoding = TmxDataEncoding.None;
    if (input.has.encoding)
    {
      switch(input.att.encoding)
      {
        case "base64": encoding = TmxDataEncoding.Base64;
        case "csv": encoding = TmxDataEncoding.CSV;
        default: throw 'Unknown encoding "${input.att.encoding}"'; //encoding = TmxDataEncoding.Unknown(input.att.encoding);
      }
    }
    
    var compression:TmxDataCompression = TmxDataCompression.None;
    if (input.has.compression)
    {
      switch (input.att.compression)
      {
        case "gzip": compression = TmxDataCompression.GZip;
        case "zlib": compression = TmxDataCompression.ZLib;
        default: throw 'Unknown compression "${input.att.compression}"';
      }
    }
    
    var chunks:Array<TmxChunk> = null;
    var tiles:Array<TmxTile> = null;
    var data:Bytes = null;
    
    inline function getRawData():String
    {
      return StringTools.trim(input.innerData);
    }
    
    inline function emptyChunk(chunk:Fast):TmxChunk
    {
      return {
        x: chunk.has.x ? Std.parseInt(chunk.att.x) : 0,
        y: chunk.has.y ? Std.parseInt(chunk.att.y) : 0,
        width: chunk.has.width ? Std.parseInt(chunk.att.width) : 0,
        height: chunk.has.height ? Std.parseInt(chunk.att.height) : 0,
        tiles: new Array()
      };
    }
    
    switch (encoding)
    {
      case TmxDataEncoding.None:
        if (isTileData)
        {
          if (input.hasNode.chunk)
          {
            // Infinite map data
            chunks = new Array();
            for (node in input.nodes.chunk)
            {
              var chunk:TmxChunk = emptyChunk(node);
              var chunkTiles:Array<TmxTile> = chunk.tiles;
              for (tile in node.nodes.tile)
              {
                chunkTiles.push( { gid:Std.parseInt(tile.att.gid), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false } );
              }
              chunks.push(chunk);
            }
          }
          else
          {
            // Regular map data
            tiles = new Array();
            for (info in input.nodes.tile)
            {
              // This tiles can have flipped flags? No documentation about this.
              tiles.push( { gid:Std.parseInt(info.att.gid), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false } );
            }
          }
        }
        else
        {
          if (compression == TmxDataCompression.None) data = Bytes.ofString(getRawData());
          else data = uncompressData(new StringInput(getRawData()), compression);
        }
      case TmxDataEncoding.CSV:
        if (isTileData)
        {
          // TODO: Optimize, avoid .split and work with string directly
          if (input.hasNode.chunk)
          {
            // Infinite map data
            chunks = new Array();
            for (node in input.nodes.chunk)
            {
              var chunk:TmxChunk = emptyChunk(node);
              var chunkTiles:Array<TmxTile> = chunk.tiles;
              var split:Array<String> = StringTools.trim(node.innerData).split(",");
              for (str in split) chunkTiles.push( { gid:Std.parseInt(str), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false } );
              chunks.push(chunk);
            }
          }
          else
          {
            tiles = new Array();
            var split:Array<String> = getRawData().split(",");
            for (str in split) tiles.push( { gid:Std.parseInt(str), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false } );
          }
        }
        else throw "CSV encoding available only for tile data";
      case TmxDataEncoding.Base64:
        var tile:Int;
        var flipH:Bool;
        inline function parseTile():TmxTile
        {
          flipH = (tile & FLIPPED_HORIZONTALLY_FLAG) == FLIPPED_HORIZONTALLY_FLAG;
          return {
            gid: tile & FLAGS_MASK,
            flippedHorizontally: flipH,
            flippedVertically: (tile & FLIPPED_VERTICALLY_FLAG) == FLIPPED_VERTICALLY_FLAG,
            flippedDiagonally: (tile & FLIPPED_DIAGONALLY_FLAG) == FLIPPED_DIAGONALLY_FLAG
          };
        }
        
        if (isTileData && input.hasNode.chunk)
        {
          chunks = new Array();
          for (node in input.nodes.chunk)
          {
            var chunk:TmxChunk = emptyChunk(node);
            var chunkTiles:Array<TmxTile> = chunk.tiles;
            
            data = haxe.crypto.Base64.decode(StringTools.trim(node.innerData));
            if (compression != TmxDataCompression.None) data = uncompressData(new BytesInput(data), compression);
            var tilesCount:Int = Std.int(data.length / 4);
            var d:BytesInput = new BytesInput(data);
            d.bigEndian = false;
            for (i in 0...tilesCount)
            {
              tile = d.readInt32();
              chunkTiles.push(parseTile());
            }
            
            chunks.push(chunk);
          }
          data = null;
        }
        else
        {
          data = haxe.crypto.Base64.decode(getRawData());
          if (compression != TmxDataCompression.None) data = uncompressData(new BytesInput(data), compression);
          
          if (isTileData)
          {
            tiles = new Array();
            var tilesCount:Int = Std.int(data.length / 4);
            var offset:Int = 0;
            var d:BytesInput = new BytesInput(data);
            d.bigEndian = false;
            for (i in 0...tilesCount)
            {
              tile = d.readInt32();
              tiles.push(parseTile());
            }
            data = null;
          }
        }
        
      case TmxDataEncoding.Unknown(value):
        throw "Unknown data encoding: " + value;
    }
    
    return {
      encoding: encoding,
      compression: compression,
      tiles: tiles,
      chunks: chunks,
      data: data
    };
  }
  
  private function uncompressData(i:Input, compression:TmxDataCompression):Bytes
  {
    switch (compression)
    {
      case TmxDataCompression.GZip: // Supported only with `format` library.
        #if format
        
        var o:BytesOutput = new BytesOutput();
        new format.gz.Reader(i).readData(o);
        return o.getBytes();
        
        #elseif debug
        throw "GZip compression currently not supported. Link 'format' library to enable GZip decompression.";
        #else
        throw "GZip compression currently not supported.";
        #end
      case TmxDataCompression.ZLib:
        return InflateImpl.run(i);
      case TmxDataCompression.None:
        return i.readAll();
      case TmxDataCompression.Unknown(value):
        throw "Unknown compression method: " + value;
    }
  }
  
  private function resolveTileLayer(input:Fast):TmxTileLayer
  {
    // Workaround to HaxeFoundation/haxe#6822
    var layer:TmxTileLayer = new TmxTileLayer(
      (input.hasNode.data ? resolveData(input.node.data) : null),
      (input.has.name ? input.att.name : ""),
      (input.has.x ? Std.parseFloat(input.att.x) : 0),
      (input.has.y ? Std.parseFloat(input.att.y) : 0),
      (input.has.offsetx ? Std.parseInt(input.att.offsetx) : 0),
      (input.has.offsety ? Std.parseInt(input.att.offsety) : 0),
      (input.has.width ? Std.parseInt(input.att.width) : width),
      (input.has.height ? Std.parseInt(input.att.height) : height),
      (input.has.opacity ? Std.parseFloat(input.att.opacity) : 1),
      (input.has.visible ? input.att.visible == "1" : true),
      resolveProperties(input)
    );
    
    return layer;
  }
  
  private inline function resolveDraworder(input:String):TmxObjectGroupDrawOrder
  {
    switch (input)
    {
      case "index": return TmxObjectGroupDrawOrder.Index;
      case "topdown": return TmxObjectGroupDrawOrder.Topdown;
      default: return TmxObjectGroupDrawOrder.Unknown(input);
    }
  }
  
  private function resolveObjectGroup(input:Fast):TmxObjectGroup
  {
    var objects:Array<TmxObject> = new Array();
    
    for (obj in input.nodes.object)
    {
      objects.push(resolveObject(obj));
    }
    
    // Workaround to HaxeFoundation/haxe#6822
    var group:TmxObjectGroup = new TmxObjectGroup(
      (input.has.draworder ? resolveDraworder(input.att.draworder) : TmxObjectGroupDrawOrder.Topdown),
      objects,
      (input.has.color ? Std.parseInt(input.att.color) : null),
      
      (input.has.name ? input.att.name : ""),
      (input.has.x ? Std.parseFloat(input.att.x) : 0),
      (input.has.y ? Std.parseFloat(input.att.y) : 0),
      (input.has.offsetx ? Std.parseInt(input.att.offsetx) : 0),
      (input.has.offsety ? Std.parseInt(input.att.offsety) : 0),
      (input.has.width ? Std.parseInt(input.att.width) : width),
      (input.has.height ? Std.parseInt(input.att.height) : height),
      (input.has.opacity ? Std.parseFloat(input.att.opacity) : 1),
      (input.has.visible ? input.att.visible == "1" : true),
      resolveProperties(input)
    );
    // group.drawOrder = input.has.draworder ? resolveDraworder(input.att.draworder) : TmxObjectGroupDrawOrder.Topdown;
    // group.objects = objects;
    return group;
    
  }
  
  private function resolveObject(obj:Fast):TmxObject
  {
    var flippedV:Bool = false;
    var flippedH:Bool = false;
    // Type specific data.
    var type:TmxObjectType = 
    if (obj.hasNode.ellipse)
    {
      TmxObjectType.OTEllipse;
    }
    else if (obj.has.gid)
    {
      #if (neko || cpp)
      var f:Float = Std.parseFloat(obj.att.gid);
      var gid:Int = f > 0x7FFFFFFF ? -Std.int(f - 2147483648) : Std.int(f); // `parseInt` on neko can't take Uint with value > INT_MAX_VALUE as input.
      #else
      var gid:Int = Std.parseInt(obj.att.gid);
      #end
      flippedH = (gid & FLIPPED_HORIZONTALLY_FLAG) == FLIPPED_HORIZONTALLY_FLAG;
      if (flippedH && gid < 0) gid = -gid;
      flippedV = (gid & FLIPPED_VERTICALLY_FLAG) == FLIPPED_VERTICALLY_FLAG;
      TmxObjectType.OTTile(gid & (FLAGS_MASK | FLIPPED_DIAGONALLY_FLAG));
    }
    else if (obj.hasNode.polygon)
    {
      TmxObjectType.OTPolygon(readPoints(obj.node.polygon));
    }
    else if (obj.hasNode.polyline)
    {
      TmxObjectType.OTPolyline(readPoints(obj.node.polyline));
    }
    else if (obj.hasNode.text)
    {
      TmxObjectType.OTText(resolveText(obj.node.text));
    }
    //else if (obj.hasNode.image) { } // TODO: Also had no docs and questionable
    else
    {
      TmxObjectType.OTRectangle;
    }
    
    var object:TmxObject = {
      id: Std.parseInt(obj.att.id), // if it's not here, you doing something wrong.
      name: obj.has.name ? obj.att.name : "",
      type: obj.has.type ? obj.att.type : "",
      x: obj.has.x ? Std.parseFloat(obj.att.x) : 0,
      y: obj.has.y ? Std.parseFloat(obj.att.y) : 0,
      width: obj.has.width ? Std.parseFloat(obj.att.width) : 0,
      height: obj.has.height ? Std.parseFloat(obj.att.height) : 0,
      rotation: obj.has.rotation ? Std.parseFloat(obj.att.rotation) : 0,
      visible: obj.has.visible ? obj.att.visible == "1" : true,
      properties: resolveProperties(obj),
      objectType: type,
      flippedHorizontally: flippedH,
      flippedVertically: flippedV,
      template: obj.has.template ? obj.att.template : null
    };
    
    if (object.type != null && object.type != "" && resolveTypeTemplate != null)
    {
      var template:TmxObjectTypeTemplate = resolveTypeTemplate(object.type);
      Tools.applyObjectTypeTemplate(object, template);
    }
    
    return object;
  }
  
  private function readPoints(input:Fast):Array<TmxPoint>
  {
    var arr:Array<TmxPoint> = new Array();
    if (input.has.points)
    {
      var points:Array<String> = input.att.points.split(" ");
      for (point in points)
      {
        var idx:Int = point.indexOf(",");
        arr.push( { x:Std.parseFloat(point.substr(0, idx)), y:Std.parseFloat(point.substr(idx + 1)) } );
      }
    }
    return arr;
  }
  
  private function resolveText(input:Fast):TmxText
  {
    return {
      fontFamily: input.has.fontfamily ? input.att.fontfamily : "sans-serif",
      pixelSize: input.has.pixelsize ? Std.parseInt(input.att.pixelsize) : 16, // TODO: Is float?
      wrap: input.has.wrap ? input.att.wrap == "1" : false,
      color: input.has.color ? resolveColor(input.att.color) : 0,
      bold: input.has.bold ? input.att.bold == "1" : false,
      italic: input.has.italic ? input.att.italic == "1" : false,
      underline: input.has.underline ? input.att.underline == "1" : false,
      strikeout: input.has.strikeout ? input.att.strikeout == "1" : false,
      kerning: input.has.kerning ? input.att.kerning == "1" : true,
      halign: input.has.halign ? input.att.halign : TmxHAlign.Left,
      valign: input.has.valign ? input.att.valign : TmxVAlign.Top,
      text: input.innerData
    }
  }
  
  private function resolveImageLayer(input:Fast):TmxImageLayer
  {
    var layer:TmxImageLayer = new TmxImageLayer(
      (input.hasNode.image ? resolveImage(input.node.image) : null),
      
      (input.has.name    ? input.att.name : ""),
      (input.has.x       ? Std.parseFloat(input.att.x) : 0),
      (input.has.y       ? Std.parseFloat(input.att.y) : 0),
      (input.has.offsetx ? Std.parseInt(input.att.offsetx) : 0),
      (input.has.offsety ? Std.parseInt(input.att.offsety) : 0),
      (input.has.width   ? Std.parseInt(input.att.width) : width),
      (input.has.height  ? Std.parseInt(input.att.height) : height),
      (input.has.opacity ? Std.parseFloat(input.att.opacity) : 1),
      (input.has.visible ? input.att.visible == "1" : true),
      resolveProperties(input)
    );
    return layer;
  }
  
  private function resolveProperties(input:Fast):TmxProperties
  {
    var props:TmxProperties = new TmxProperties();
    var value:String;
    if (input.hasNode.properties)
    {
      for (prop in input.node.properties.nodes.property)
      {
        value = prop.has.value ? prop.att.value : prop.innerData;
        if (prop.has.type)
        {
          switch(prop.att.type)
          {
            case "int": 
              props.setRaw(prop.att.name, value, PTInt);
            case "float":
              props.setRaw(prop.att.name, value, PTFloat);
            case "bool": 
              props.setRaw(prop.att.name, value, PTBool);
            case "color":
              props.setRaw(prop.att.name, value, PTColor);
            case "file":
              props.setRaw(prop.att.name, value, PTFile);
            default:
              props.setRaw(prop.att.name, value, PTString);
          }
        }
        else
        {
          props.setRaw(prop.att.name, value, PTString);
        }
        
      }
    }
    return props;
  }
  
}