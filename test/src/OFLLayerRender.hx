package;
import format.tmx.Data.TmxMap;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxTileset;
import format.tmx.Data.TmxTile;
import format.tmx.Tools;
import haxe.io.Path;
import openfl.Assets;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import tiled.TileLayerRenderer;

/**
 * ...
 * @author Yanrishatum
 */
class OFLLayerRender extends Sprite
{
  
  private var render:InternalOFLRender;
  
  public function new(map:TmxMap, layer:TmxTileLayer)
  {
    super();
    render = new InternalOFLRender(map, layer);
    render.g = graphics;
    render.render();
  }
  
  
  
}

private class InternalOFLRender extends TileLayerRenderer
{
  public var g:Graphics;
  private var m:Matrix = new Matrix();
  private var uv:Point = new Point();
  
  override function renderOrthoTile(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void 
  {
    if (tileset.tileOffset != null)
    {
      x += tileset.tileOffset.x;
      y += tileset.tileOffset.y;
    }
    Tools.getTileUVByLidUnsafe(tileset, tile.gid - tileset.firstGID, uv);
    m.setTo(1, 0, 0, 1, x - uv.x, y - uv.y + map.tileHeight - tileset.tileHeight);
    g.beginBitmapFill(Assets.getBitmapData(Path.join([ "assets/" , tileset.image.source])), m, false);
    g.drawRect(x, y + map.tileHeight - tileset.tileHeight, tileset.tileWidth, tileset.tileHeight);
  }
  
}