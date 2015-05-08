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
    return null;
  }
  
  public static function getTileUVByLidUnsafe(tileset:TmxTileset, localId:Int, output:Dynamic):Void
  {
    var tilesInLine:Int = Math.floor(tileset.image.width / tileset.tileWidth);
    Reflect.setProperty(output, "x", (localId % tilesInLine) * tileset.tileWidth);
    Reflect.setProperty(output, "y", Math.ffloor(localId / tilesInLine) * tileset.tileHeight);
  }
  
}