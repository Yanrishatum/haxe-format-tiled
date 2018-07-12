package;

import sys.io.FileOutput;
import format.tmx.Data;
import format.tmx.Reader;
import sys.io.File;
import haxe.io.Bytes;

class Main
{
  private static macro function getFName():haxe.macro.Expr
  {
    var name = "output/" + haxe.macro.Context.definedValue("build_type");
    return macro $v{name};
  }
  
  #if verify_mode
  
  public static function main()
  {
    var files = sys.FileSystem.readDirectory("output");
    var master:Bytes = sys.io.File.getBytes(getFName());
    
    var tc = Std.int(master.length / 5);
    trace("Verifying against: " + getFName());
    for (file in files)
    {
      if ("output/" + file == getFName()) continue; // Master
      var slave:Bytes = sys.io.File.getBytes("output/" + file);
      var o:Int = 0;
      for (i in 0...tc)
      {
        if (slave.getInt32(o) != master.getInt32(o) || slave.get(o + 4) != master.get(o + 4))
        {
          trace('$file tile $i: Invalid tile GID; Flip: ${slave.get(o + 4)}');
        }
        o += 5;
      }
    }
  }
  
  #else
  
  public static function main()
  {
    dump();
    
  }
  
  #end
  
  private static function dump()
  {
    trace("Target: " + getFName());
    var fio:FileOutput = File.write(getFName());
    var tmx:TmxMap = new Reader().read(Xml.parse(File.getContent("files/orthogonaloutside.tmx")));
    for (layer in tmx.layers)
    {
      switch (layer)
      {
        case TmxLayer.LTileLayer(tl):
          for (t in tl.data.tiles)
          {
            fio.writeInt32(t.gid);
            fio.writeByte(t.flippedHorizontally ? 1 : 0);
          }
        default:
        
      }
    }
    fio.close();
  }
  
}