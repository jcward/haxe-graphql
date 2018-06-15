class Test {
    static function main() {
        trace("Haxe is great!");

        var d:Dog = null;
        var c:Cat = null;
        var a:Animal;

        { // should all work
          a = c;
          a = d;
          takesAnimal(c);
          takesAnimal(d);
          takesAnimal(a);
        }

        { // should all fail to compile
          a = new Test();
          c = 123;
          d = {};
          takesAnimal("");
          takesAnimal(new Test());
          takesAnimal(Test);
        }
    }
    
    static function takesAnimal(a:Animal) {}
}

class Dog {}
class Cat {}

// union Animal = Dog | Cat
abstract Animal(Any) {
    @:from static function fromDog(v:Dog) return cast v;
    @:from static function fromCat(v:Cat) return cast v;
}
