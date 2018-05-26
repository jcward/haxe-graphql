package;

@:forward
abstract ArrayStringMap<T>(haxe.ds.StringMap<T>) from haxe.ds.StringMap<T> to haxe.ds.StringMap<T> {
  public function new() { return new haxe.ds.StringMap<T>(); }
  @:arrayAccess
  public inline function get(key:String) {
    return this.get(key);
  }
  @:arrayAccess
  public inline function arrayWrite(k:String, v:T):T {
    this.set(k, v);
    return v;
  }
}
