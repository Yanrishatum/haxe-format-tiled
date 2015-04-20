package;

import format.tmx.Data.TmxMap;
import format.tmx.Reader;
import luxe.Input;
import luxe.resource.Resource.TextResource;

class Main extends luxe.Game 
{
	override function ready() 
	{
    Luxe.loadText("assets/desert.tmx", onload);
	}
  
  private function onload(r:TextResource):Void
  {
    var r:Reader = new Reader(Xml.parse(r.text));
    var t:TmxMap = r.read();
    
    untyped __cpp__("cout") << untyped __cpp__("sizeof")(t);
    //trace(t);
  }

	override function onkeyup(e:KeyEvent) 
	{
		if(e.keycode == Key.escape)
			Luxe.shutdown();
	}

	override function update(dt:Float) 
	{
	}
}
