package tiled;
import format.tmx.Data.TmxMap;
import format.tmx.Data.TmxOrientation;
import format.tmx.Data.TmxRenderOrder;
import format.tmx.Data.TmxStaggerAxis;
import format.tmx.Data.TmxStaggerIndex;
import format.tmx.Data.TmxTile;
import format.tmx.Data.TmxTileLayer;
import format.tmx.Data.TmxTileset;
import format.tmx.Tools;

/**
 * Basic abstract rendering for tile layers. Not the fastest one, but should get you started.
 * @author Yanrishatum
 */
class TileLayerRenderer
{
  
  public var renderX:Float;
  public var renderY:Float;
  
  private var map:TmxMap;
  private var layer:TmxTileLayer;

  public function new(map:TmxMap, layer:TmxTileLayer) 
  {
    this.map = map;
    this.layer = layer;
    renderX = 0;
    renderY = 0;
  }
  
  public function render():Void
  {
    // Only orthogonal is implemented properly. Others are buggy/not implemented/incomplete
    switch (map.orientation)
    {
      case TmxOrientation.Orthogonal:
        renderOrthogonal();
      case TmxOrientation.Isometric:
        renderIsometric();
      case TmxOrientation.Staggered:
        
      case TmxOrientation.Hexagonal:
        renderHexagonal();
      case TmxOrientation.Unknown(v):
        // Do nothing
    }
  }
  
  private function renderOrthogonal():Void
  {
    // TODO: Regard renderorder
    if (map.infinite)
    {
      if (layer.data.chunks != null)
      {
        for (chunk in layer.data.chunks)
        {
          renderOrthoTiles(renderX + layer.offsetX + chunk.x * map.tileWidth, renderY + layer.offsetY + chunk.y * map.tileHeight, chunk.tiles, chunk.width);
        }
      }
    }
    else
    {
      renderOrthoTiles(renderX + layer.offsetX, renderY + layer.offsetY, layer.data.tiles, layer.width);
    }
  }
  
  /**
     Override for optimized rendering
  **/
  private function renderOrthoTiles(ox:Float, y:Float, tiles:Array<TmxTile>, width:Int):Void
  {
    var i:Int = 0;
    var ix:Int = 0;
    var x:Float = ox;
    var tset:TmxTileset;
    var tile:TmxTile;
    while (i < tiles.length)
    {
      tile = tiles[i];
      if (tile.gid != 0)
      {
        renderOrthoTile(x, y, tile, Tools.getTilesetByGid(map, tile.gid));
      }
      i++;
      if (++ix == width)
      {
        ix = 0;
        x = ox;
        y += map.tileHeight;
      }
      else
      {
        x += map.tileWidth;
      }
    }
  }
  
  private function renderOrthoTile(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void
  {
    throw "Not implemented";
  }
  
  private function renderHexagonal():Void
  {
    if (map.infinite)
    {
      renderOrthogonal(); // TODO
    }
    else
    {
      renderHexaTiles(renderX + layer.offsetX, renderY + layer.offsetX, map.staggerIndex == TmxStaggerIndex.Odd, layer.data.tiles, layer.width);
    }
  }
  
  private function renderHexaTiles(ox:Float, y:Float, isEven:Bool, tiles:Array<TmxTile>, width:Int):Void
  {
    var baseEven:Bool = isEven;
    var i:Int = 0;
    var ix:Int = 0;
    var x:Float = isEven ? ox : ox + map.tileWidth / 2;
    
    var tile:TmxTile;
    var staggerHor:Bool = map.staggerAxis == TmxStaggerAxis.AxisX; // Not properly supported yet
    while (i < tiles.length)
    {
      tile = tiles[i];
      renderHexaTile(x, y + (staggerHor && !isEven ? map.tileHeight / 2 : 0), tile, Tools.getTilesetByGid(map, tile.gid));
      i++;
      if (++ix == width)
      {
        ix = 0;
        if (staggerHor)
        {
          isEven = baseEven;
          y += map.tileHeight;
          x = ox;
        }
        else
        {
          y += (map.tileHeight - map.hexSideLength) / 2 + map.hexSideLength;
          isEven = !isEven;
          x = isEven ? ox : ox + map.tileWidth / 2;
        }
      }
      else
      {
        if (staggerHor)
        {
          x += (map.tileWidth - map.hexSideLength) / 2 + map.hexSideLength;
          isEven = !isEven;
        }
        else
        {
          x += map.tileWidth;
        }
      }
    }
  }
  
  private function renderHexaTile(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void
  {
    renderOrthoTile(x, y, tile, tileset);
  }
  
  private function renderIsometric():Void
  {
    if (map.infinite)
    {
      renderOrthogonal();
    }
    else
    {
      renderIsoTiles(renderX + layer.offsetX, renderY + layer.offsetX, layer.data.tiles, layer.width, layer.height);
    }
  }
  
  private function renderIsoTiles(ox:Float, y:Float, tiles:Array<TmxTile>, width:Int, height:Int):Void
  {
    var i:Int = 0;
    var ix:Int = 0;
    var iy:Int = 0;
    var x:Float = ox;
    var tset:TmxTileset;
    var tile:TmxTile;
    var hw:Float = map.tileWidth / 2;
    var hh:Float = map.tileHeight / 2;
    
    while (i < tiles.length)
    {
      tile = tiles[i];
      renderIsoTile(x + ((ix - iy) * width), y + (ix + iy) * height, tile, Tools.getTilesetByGid(map, tile.gid));
      i++;
      if (++ix == width)
      {
        ix = 0;
        iy++;
        //x = ox;
        //y += hh;
      }
      else
      {
        //x += hw;
      }
    }
  }
  
  private function renderIsoTile(x:Float, y:Float, tile:TmxTile, tileset:TmxTileset):Void
  {
    renderOrthoTile(x, y, tile, tileset);
  }
  
}