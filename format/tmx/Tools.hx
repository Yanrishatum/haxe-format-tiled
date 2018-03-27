package format.tmx;
import format.tmx.Data;

/**
 * ...
 * @author Yanrishatum
 */
class Tools
{
  
  public static function applyTSX(tsx:TmxTileset, base:TmxTileset):Void
  {
    base.properties = tsx.properties;
    base.name = tsx.name;
    base.columns = tsx.columns;
    base.grid = tsx.grid;
    base.image = tsx.image;
    base.margin = tsx.margin;
    //base.source = tsx.source;
    base.spacing = tsx.spacing;
    base.tileOffset = tsx.tileOffset;
    base.tileCount = tsx.tileCount;
    base.tileHeight = tsx.tileHeight;
    base.tileWidth = tsx.tileWidth;
    base.terrainTypes = tsx.terrainTypes;
    base.tiles = tsx.tiles;
    base.wangSets = tsx.wangSets;
  }
  
  public static function applyObjectTypeTemplate(obj:TmxObject, ot:TmxObjectTypeTemplate):Void
  {
    var props:TmxProperties = obj.properties;
    for (prop in ot.properties)
    {
      if (prop.defaultValue != null && !props.exists(prop.name))
      {
        props.setRaw(prop.name, prop.defaultValue, prop.type);
      }
    }
  }
  
  //public static function applyTemplate(obj:TmxObject, template:TmxObjectTemplate):Void
  //{
    //obj.template
  //}
  
  /**
   * Returns linear array of layers removing all nested groups. 
   * IMPORTANT! This function will apply group offset/opacity/visibility values to nested layers, don't use it if you need to keep them unchanged.
   */
  public static function linearLayers(map:TmxMap):Array<TmxLayer>
  {
    var linear:Array<TmxLayer> = new Array();
    for (l in map.layers)
    {
      switch (l)
      {
        case LGroup(group):
          linearLayersInternal(group, linear);
        default:
          linear.push(l);
      }
    }
    return linear;
  }
  
  private static function linearLayersInternal(group:TmxGroup, output:Array<TmxLayer>):Void
  {
    for (layer in group.layers)
    {
      switch (layer)
      {
        case LGroup(g):
          g.offsetX += group.offsetX;
          g.offsetY += group.offsetY;
          g.visible = group.visible;
          g.opacity *= group.opacity;
          linearLayersInternal(g, output);
        case LObjectGroup(g):
          g.offsetX += group.offsetX;
          g.offsetY += group.offsetY;
          g.visible = group.visible;
          g.opacity *= group.opacity;
          output.push(layer);
        case LTileLayer(l):
          l.offsetX += group.offsetX;
          l.offsetY += group.offsetY;
          l.visible = group.visible;
          l.opacity *= group.opacity;
          output.push(layer);
        case LImageLayer(l):
          l.offsetX += group.offsetX;
          l.offsetY += group.offsetY;
          l.visible = group.visible;
          l.opacity *= group.opacity;
          output.push(layer);
      }
    }
  }
  
  /**
     Propagates properties from Object Type Template for specific object
     @param obj
     @param types
  **/
  public static function propagateObjectTypeToObject(obj:TmxObject, types:Map<String, TmxObjectTypeTemplate>):Void
  {
    if (obj.type != null)
    {
      var type:TmxObjectTypeTemplate = types.get(obj.type);
      if (type != null)
      {
        var props:TmxProperties = obj.properties;
        for (prop in type.properties)
        {
          if (!props.exists(prop.name) && prop.defaultValue != null)
          {
            props.setRaw(prop.name, prop.defaultValue, prop.type);
          }
        }
      }
    }
  }
  
  /**
     Propagates tile properties of tile object in tileset to specific object.
     @param obj Object to propagate tile data to.
     @param map 
     @param gid Global tile ID from which to take properties.
  **/
  public static function propagateTilePropertiesToObject(obj:TmxObject, map:TmxMap, gid:Int):Void
  {
    var tset:TmxTileset = getTilesetByGid(map, gid);
    if (tset != null && tset.tiles != null)
    {
      var lid:Int = gid - tset.firstGID;
      for (tile in tset.tiles)
      {
        if (tile.id == lid)
        {
          tile.properties.propagateTo(obj.properties);
          if (tile.type != null && (obj.type == null || obj.type == "")) obj.type = tile.type;
        }
      }
    }
  }
  
  public static function propagateTileProperties(map:TmxMap):Void
  {
    for (layer in map.layers)
    {
      propagateTilePropertiesLayer(map, layer);
    }
  }
  
  private static function propagateTilePropertiesLayer(map:TmxMap, layer:TmxLayer)
  {
    var tset:TmxTileset;
    
    switch (layer)
    {
      case TmxLayer.LObjectGroup(group):
        for (obj in group.objects)
        {
          switch (obj.objectType)
          {
            case TmxObjectType.OTTile(gid):
              tset = getTilesetByGid(map, gid);
              var lid:Int = gid - tset.firstGID;
              for (tile in tset.tiles)
              {
                if (tile.id == lid)
                {
                  tile.properties.propagateTo(obj.properties);
                  if (tile.type != null && (obj.type == null || obj.type == "")) obj.type = tile.type;
                }
              }
            default:
              
          }
        }
      case TmxLayer.LGroup(g):
        for (l in g.layers) propagateTilePropertiesLayer(map, l);
      default:
        
    }
  }
  
  /**
     Propagates properties from Object Type templates to all objects on the map.
     @param map Map to which properties should propagate.
     @param types List of Object Type Templates by names.
     @param propagateObjectLayers Should propagate to objects on ObjectLayers?
     @param propagateTileColliders Should propagate to objects in collisions of tile objects?
  **/
  public static function propagateObjectTypes(map:TmxMap, types:Map<String, TmxObjectTypeTemplate>, propagateObjectLayers:Bool = true, propagateTileColliders:Bool = true):Void
  {
    inline function propagate(obj:TmxObject)
    {
      if (obj.type != null)
      {
        var type:TmxObjectTypeTemplate = types.get(obj.type);
        if (type != null)
          for (prop in type.properties)
            if (!obj.properties.exists(prop.name) && prop.defaultValue != null)
              obj.properties.setRaw(prop.name, prop.defaultValue, prop.type);
      }
    }
    
    function propagateLayer(layer:TmxLayer):Void
    {
        switch (layer)
        {
          case TmxLayer.LObjectGroup(o):
            for (obj in o.objects) propagate(obj);
          case TmxLayer.LGroup(g):
            for (layer in g.layers) propagateLayer(layer);
          default:
            
        }
    }
    
    if (propagateTileColliders)
      for (tset in map.tilesets)
        if (tset.tiles != null)
          for (tile in tset.tiles)
            if (tile.objectGroup != null)
              for (obj in tile.objectGroup.objects) propagate(obj);
    
    if (propagateObjectLayers)
    {
      for (l in map.layers)
      {
        propagateLayer(l);
      }
    }
  }
  
  /**
     Returns Tile settings for given tile global ID.
  **/
  public static function getTileByGid(map:TmxMap, gid:Int):TmxTilesetTile
  {
    var tset:TmxTileset = getTilesetByGid(map, gid);
    if (tset != null && tset.tiles != null)
    {
      var lid:Int = gid - tset.firstGID;
      for (tile in tset.tiles)
      {
        if (tile.id == lid) return tile;
      }
    }
    return null;
  }
  
  /**
     Returns tileset in which given global ID present.
  **/
  public static function getTilesetByGid(map:TmxMap, gid:Int):TmxTileset
  {
    if (gid <= 0) return null; // None
    var i:Int = 0;
    while (i < map.tilesets.length)
    {
      if (map.tilesets[i].firstGID > gid) return map.tilesets[i - 1];
      i++;
    }
    return map.tilesets[i - 1];
  }
  
  /**
     Returns tileset index in which given global ID present.
  **/
  public static function getTilesetIndexByGid(map:TmxMap, gid:Int):Int
  {
    if (gid <= 0) return -1; // None
    var i:Int = 0;
    while (i < map.tilesets.length)
    {
      if (map.tilesets[i].firstGID > gid) return i - 1;
      i++;
    }
    return i - 1;
  }
  
  /**
   * Sets `x` and `y` values to `output` relative to tile position on source image of tileset.
   * Note: Currently do not supports non-zero margin and spacing values.
   * @param tileset
   * @param localId
   * @param output
   */
  public static function getTileUVByLidUnsafe(tileset:TmxTileset, localId:Int, output:Dynamic):Void
  {
    var tilesInLine:Int = getTilesCountInLineOnTileset(tileset);// Math.floor(tileset.image.width / tileset.tileWidth);
    Reflect.setProperty(output, "x", (localId % tilesInLine) * (tileset.tileWidth + tileset.spacing) + tileset.margin);
    Reflect.setProperty(output, "y", Math.ffloor(localId / tilesInLine) * (tileset.tileHeight + tileset.spacing) + tileset.margin);
  }
  
  /**
   * Shifts origin of objects from bottom-left edge to top-left edge.
   * Left out for compatibility
   * @param map
   */
  public static inline function fixObjectPlacement(map:TmxMap):Void topLeftObjectOrigin(map);
  /**
   * Shifts origin of objects from bottom-left edge to top-left edge.
   * @param map
   */
  public static function topLeftObjectOrigin(map:TmxMap):Void
  {
    var toRad:Float = Math.PI / 180;
    for (type in map.layers)
    {
      switch (type)
      {
        case TmxLayer.LObjectGroup(group):
          for (obj in group.objects)
          {
            var height:Null<Float> = obj.height;
            if (height == null || height == 0)
            {
              switch (obj.objectType)
              {
                case TmxObjectType.OTTile(gid):
                  var tset:TmxTileset = getTilesetByGid(map, gid);
                  if (tset != null && tset.tileHeight != null) height = tset.tileHeight;
                  else height = map.tileHeight;
                default:
                  height = map.tileHeight;
              }
            }
            var radians:Float = obj.rotation * toRad;
            obj.x += Math.sin(radians) * height;
            obj.y -= Math.cos(radians) * height;
          }
        default:
      }
    }
  }
  
  /**
     Returns amount of tiles in one line in given tileset. Use it for UV calculation.
  **/
  public static function getTilesCountInLineOnTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.width - tileset.margin * 2 + tileset.spacing) / (tileset.tileWidth + tileset.spacing));
  }
  
  /**
     Returns amount of tiles in one column in given tileset. UV calculation.
  **/
  public static function getTilesCountInColumnOnTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.height - tileset.margin * 2 + tileset.spacing) / (tileset.tileHeight + tileset.spacing));
  }
  
  /**
     Returns total amount of tiles in tileset. 
  **/
  public static function getTilesCountInTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.width - tileset.margin * 2 + tileset.spacing) / (tileset.tileWidth + tileset.spacing)) *
           Math.floor((tileset.image.height - tileset.margin * 2 + tileset.spacing) / (tileset.tileHeight + tileset.spacing));
  }
  
}