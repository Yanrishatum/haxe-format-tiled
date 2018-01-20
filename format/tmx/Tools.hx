package format.tmx;
import format.tmx.Data;

/**
 * ...
 * @author Yanrishatum
 */
class Tools
{

  /*
  public static function getTilesetByGidSafe(map:TmxMap, gid:Int):TmxTileset
  {
    if (gid <= 0) return null; // None
    var i:Int = map.tilesets.length;
    while (--i >= 0)
    {
      if (map.tilesets[i].firstGID >= gid)
      {
        if (map.tilesets.length - 1 == i)
        {
          var t:TmxTileset = map.tilesets[i];
          // UNIMPLEMENTED
        }
        return map.tilesets[i];
      }
    }
  }*/
  
  public static function propagateObjectTypeToObject(obj:TmxObject, types:Map<String, TmxObjectTypeTemplate>):Void
  {
    if (obj.type != null)
    {
      var type:TmxObjectTypeTemplate = types.get(obj.type);
      if (type != null)
        for (prop in type.properties)
          if (!obj.properties.exists(prop.name) && prop.defaultValue != null)
            obj.properties.set(prop.name, prop.defaultValue);
    }
  }
  
  public static function propagateTilePropertiesToObject(obj:TmxObject, map:TmxMap, gid:Int):Void
  {
    var tset:TmxTileset = getTilesetByGid(map, gid);
    if (tset != null && tset.tiles != null)
    {
      var lid:Int = gid - tset.firstGID;
      for (tile in tset.tiles)
      {
        if (tile.id == lid && tile.properties != null)
        {
          for (prop in tile.properties.keys())
            if (!obj.properties.exists(prop))
              obj.properties.set(prop, tile.properties.get(prop));
          if (tile.type != null && (obj.type == null || obj.type == "")) obj.type = tile.type;
        }
      }
    }
  }
  
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
              obj.properties.set(prop.name, prop.defaultValue);
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
        switch (l)
        {
          case TmxLayer.ObjectGroup(o):
            for (obj in o.objects) propagate(obj);
          default:
            
        }
      }
    }
  }
  
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
    // Must use spacing and margin values for calculation.
    var tilesInLine:Int = Math.floor(tileset.image.width / tileset.tileWidth);
    Reflect.setProperty(output, "x", (localId % tilesInLine) * tileset.tileWidth);
    Reflect.setProperty(output, "y", Math.ffloor(localId / tilesInLine) * tileset.tileHeight);
  }
  
  /**
   * Shifts origin of objects from bottom-left edge to top-left edge.
   * @param map
   */
  public static function fixObjectPlacement(map:TmxMap):Void
  {
    var toRad:Float = Math.PI / 180;
    for (type in map.layers)
    {
      switch (type)
      {
        case TmxLayer.ObjectGroup(group):
          for (obj in group.objects)
          {
            var height:Null<Float> = obj.height;
            if (height == null || height == 0)
            {
              switch (obj.objectType)
              {
                case TmxObjectType.Tile(gid):
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
  
  public static function getTilesCountInLineOnTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.width - tileset.margin * 2 + tileset.spacing) / (tileset.tileWidth + tileset.spacing));
  }
  
  public static function getTilesCountInColumnOnTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.height - tileset.margin * 2 + tileset.spacing) / (tileset.tileHeight + tileset.spacing));
  }
  
  public static function getTilesCountInTileset(tileset:TmxTileset):Int
  {
    return Math.floor((tileset.image.width - tileset.margin * 2 + tileset.spacing) / (tileset.tileWidth + tileset.spacing)) *
           Math.floor((tileset.image.height - tileset.margin * 2 + tileset.spacing) / (tileset.tileHeight + tileset.spacing));
  }
  
}