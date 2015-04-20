package format.tmx;
import format.tmx.Data;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.StringInput;
import haxe.xml.Fast;
import haxe.zip.InflateImpl;
import haxe.zip.Uncompress;

/**
 * ...
 * @author Yanrishatum
 */
class Reader
{
  private var xml:Xml;
  private var f:Fast;
  
  private var customUncompressors:Map<String, String->Bytes>;
  private var customEncoders:Map<String, Bytes->String->Array<TmxTile>>;
  
  private var width:Int;
  private var height:Int;
  
  public function new(xml:Xml) 
  {
    this.xml = xml;
    this.f = new Fast(xml);
  }
  
  public function read():TmxMap
  {
    var map:Fast = f.node.map;
    
    var properties:Map<String, String> = resolveProperties(map);
    var tilesets:Array<TmxTileset> = new Array();
    var layers:Array<TmxLayer> = new Array();
    
    for (element in map.elements)
    {
      switch (element.name)
      {
        case "tileset": tilesets.push(resolveTileset(element));
        case "layer": layers.push(TmxLayer.TileLayer(resolveTileLayer(element)));
        case "objectgroup": layers.push(TmxLayer.ObjectGroup(resolveObjectGroup(element)));
        case "imagelayer": layers.push(TmxLayer.ImageLayer(resolveImageLayer(element)));
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
      layers: layers
    };
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
  
  private inline function resolveTileset(input:Fast):TmxTileset
  {
    var properties:Map<String, String> = resolveProperties(input);
    var terrains:Array<TmxTerrain> = new Array();
    var tiles:Array<TmxTilesetTile> = new Array();
    var tileOffset:TmxTileOffset = null;
    
    if (input.hasNode.tileoffset)
    {
      var node:Fast = input.node.tileoffset;
      tileOffset = { x:Std.parseInt(node.att.x), y:Std.parseInt(node.att.y) };
    }
    
    if (input.hasNode.terraintypes)
    {
      for (node in input.node.terraintypes.nodes.terrain)
      {
        terrains.push( { name:node.att.name, tile:Std.parseInt(node.att.tile), properties:resolveProperties(node) } );
      }
    }
    
    if (input.hasNode.tile)
    {
      for (node in input.nodes.tile)
      {
        tiles.push( {
         id: Std.parseInt(node.att.id),
         terrain: node.has.terrain ? node.att.terrain : null,
         probability: node.has.probability ? Std.parseFloat(node.att.probability) : 0,
         properties: resolveProperties(node),
         image: node.hasNode.image ? resolveImage(node.node.image) : null,
         objectGroup: node.hasNode.objecgroup ? resolveObjectGroup(node.node.objectgroup) : null
        });
      }
    }
    
    return
    {
      firstGID: Std.parseInt(input.att.firstgid),
      source: input.has.source ? input.att.source : null,
      name: input.att.name,
      tileWidth: Std.parseInt(input.att.tilewidth),
      tileHeight: Std.parseInt(input.att.tileheight),
      spacing: input.has.spacing ? Std.parseInt(input.att.spacing) : 0,
      margin: input.has.margin ? Std.parseInt(input.att.margin) : 0,
      properties: properties,
      image: input.hasNode.image ? resolveImage(input.node.image) : null,
      terrainTypes: terrains,
      tiles: tiles,
      tileOffset: tileOffset
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
    
    var tiles:Array<TmxTile> = null;
    var rawData:String = StringTools.trim(input.innerData);
    var data:Bytes = null;
    
    switch (encoding)
    {
      case TmxDataEncoding.None:
        if (isTileData)
        {
          tiles = new Array();
          for (info in input.nodes.tile)
          {
            // This tiles can have an flipped flags? No documentation about this.
            tiles.push( { gid:Std.parseInt(info.att.gid), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false } );
          }
        }
        else
        {
          if (compression == TmxDataCompression.None) data = Bytes.ofString(rawData);
          else data = uncompressData(new StringInput(rawData), compression);
        }
      case TmxDataEncoding.CSV:
        if (isTileData)
        {
          tiles = new Array();
          var split:Array<String> = rawData.split(",");
          for (str in split) tiles.push({ gid:Std.parseInt(str), flippedVertically:false, flippedHorizontally:false, flippedDiagonally:false });
        }
        else throw "CSV encoding available only for tile data";
      case TmxDataEncoding.Base64:
        data = haxe.crypto.Base64.decode(rawData);
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
            var tile:Int = d.readInt32();
            tiles.push( {
              gid: tile & FLAGS_MASK,
              flippedHorizontally: (tile & FLIPPED_HORIZONTALLY_FLAG) == FLIPPED_HORIZONTALLY_FLAG,
              flippedVertically: (tile & FLIPPED_VERTICALLY_FLAG) == FLIPPED_VERTICALLY_FLAG,
              flippedDiagonally: (tile & FLIPPED_DIAGONALLY_FLAG) == FLIPPED_DIAGONALLY_FLAG
            });
          }
          data = null;
        }
    }
    
    return {
      encoding: encoding,
      compression: compression,
      tiles: tiles,
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
    }
  }
  
  private function resolveTileLayer(input:Fast):TmxTileLayer
  {
    return {
      name:input.att.name,
      x: input.has.x ? Std.parseFloat(input.att.x) : 0,
      y: input.has.y ? Std.parseFloat(input.att.y) : 0,
      width: input.has.width ? Std.parseInt(input.att.width) : width,
      height: input.has.height ? Std.parseInt(input.att.height) : height,
      opacity: input.has.opacity ? Std.parseFloat(input.att.opacity) : 1,
      visible: input.has.visible ? input.att.visible == "1" : true,
      properties: resolveProperties(input),
      data: input.hasNode.data ? resolveData(input.node.data) : null
    };
  }
  
  private function resolveObjectGroup(input:Fast):TmxObjectGroup
  {
    var objects:Array<TmxObject> = new Array();
    
    for (obj in input.nodes.object)
    {
      // Type specific data.
      var type:TmxObjectType = 
      if (obj.hasNode.ellipse) TmxObjectType.Ellipse;
      else if (obj.has.gid) TmxObjectType.Tile(Std.parseInt(obj.att.gid));
      else if (obj.hasNode.polygon) TmxObjectType.Polygon(readPoints(obj.node.polygon));
      else if (obj.hasNode.polyline) TmxObjectType.Polyline(readPoints(obj.node.polyline));
      else TmxObjectType.Rectangle;
      
      // Unificated data.
      objects.push({
        id: Std.parseInt(obj.att.id),
        name: obj.has.name ? obj.att.name : "",
        type: obj.has.type ? obj.att.type : "",
        x: obj.has.x ? Std.parseFloat(obj.att.x) : 0,
        y: obj.has.y ? Std.parseFloat(obj.att.y) : 0,
        width: obj.has.width ? Std.parseFloat(obj.att.width) : 0,
        height: obj.has.height ? Std.parseFloat(obj.att.height) : 0,
        rotation: obj.has.rotation ? Std.parseFloat(obj.att.rotation) : 0,
        visible: obj.has.visible ? obj.att.visible == "1" : true,
        properties: resolveProperties(obj),
        objectType: type
      });
    }
    
    return {
      name:input.att.name,
      x: input.has.x ? Std.parseFloat(input.att.x) : 0,
      y: input.has.y ? Std.parseFloat(input.att.y) : 0,
      width: input.has.width ? Std.parseInt(input.att.width) : width,
      height: input.has.height ? Std.parseInt(input.att.height) : height,
      opacity: input.has.opacity ? Std.parseFloat(input.att.opacity) : 1,
      visible: input.has.visible ? input.att.visible == "1" : true,
      properties: resolveProperties(input),
      objects: objects
    };
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
  
  private function resolveImageLayer(input:Fast):TmxImageLayer
  {
    return {
      name:input.att.name,
      x: input.has.x ? Std.parseFloat(input.att.x) : 0,
      y: input.has.y ? Std.parseFloat(input.att.y) : 0,
      width: input.has.width ? Std.parseInt(input.att.width) : width,
      height: input.has.height ? Std.parseInt(input.att.height) : height,
      opacity: input.has.opacity ? Std.parseFloat(input.att.opacity) : 1,
      visible: input.has.visible ? input.att.visible == "1" : true,
      properties: resolveProperties(input),
      image: input.hasNode.image ? resolveImage(input.node.image) : null
    };
  }
  
  private function resolveProperties(input:Fast):Map<String, String>
  {
    var props:Map<String, String> = new Map();
    if (input.hasNode.properties)
    {
      for (prop in input.node.properties.nodes.property)
      {
        props.set(prop.att.name, prop.att.value);
      }
    }
    return props;
  }
  
}