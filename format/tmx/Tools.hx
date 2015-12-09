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