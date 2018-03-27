package;

import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxMap;
import format.tmx.Data.TmxTileset;
import format.tmx.Reader;
import haxe.CallStack;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;

class Main extends Sprite
{
  private var r:Reader;
  
  public function new()
  {
    super();
    try
    {
      
      r = new Reader();
      r.resolveTSX = getTSX;
      tsx = new Map();
      //var t:TmxMap = r.read(Xml.parse(Assets.getText("assets/desert.tmx")));
      //var t:TmxMap = r.read(Xml.parse(Assets.getText("assets/hexagonal-mini.tmx")));
      //var t:TmxMap = r.read(Xml.parse(Assets.getText("assets/isometric_grass_and_water.tmx")));
      var t:TmxMap = r.read(Xml.parse(Assets.getText("assets/sewers.tmx")));
      
      //scaleX = scaleY = 2;
      //x = 20;
      x = Lib.current.stage.stageWidth / 2;
      y = 20;
      for (l in t.layers)
      {
        switch (l)
        {
          case TmxLayer.LTileLayer(tl):
            addChild(new OFLLayerRender(t, tl));
          default:
            
        }
      }
    }
    catch (e:Dynamic)
    {
      trace(e);
      trace(CallStack.toString(CallStack.exceptionStack()));
    }
    //untyped __cpp__("cout") << untyped __cpp__("sizeof")(t);
  }
  
  private var tsx:Map<String, TmxTileset>;
  private function getTSX(name:String):TmxTileset
  {
    var cached:TmxTileset = tsx.get(name);
    if (cached != null) return cached;
    cached = r.readTSX(Xml.parse(Assets.getText("assets/" + name)));
    tsx.set(name, cached);
    return cached;
  }
  
}
