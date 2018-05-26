package;

import haxe.macro.Context;
import haxe.macro.Expr;

import haxe.ds.Either;

// By @jbaudi and @fponticelli, https://gist.github.com/mrcdk/d881f85d64379e4384b1

abstract OneOf<A, B>(Either<A, B>) from Either<A, B> to Either<A, B> {
  @:from inline static function fromA<A, B>(a:A) : OneOf<A, B> return Left(a);
  @:from inline static function fromB<A, B>(b:B) : OneOf<A, B> return Right(b);

  @:to inline function toA():Null<A> return switch(this) {case Left(a): a; default: null;}
  @:to inline function toB():Null<B> return switch(this) {case Right(b): b; default: null;}

  @:from inline static macro function fromDynamic<A, B>(d:ExprOf<Dynamic>) : Expr
  {
    // TODO: is it possible to use RTTI here? I'd have to know what types A and B are...
    Context.error('Can\'t pass a Dynamic into OneOf<A,B>', d.pos);
    return null;
  }

  // auto OneOf<A,B> <--> OneOf<B,A>
  @:to inline function swap():OneOf<B, A> return switch this {case Right(b): Left(b); case Left(a): Right(a);}
}
