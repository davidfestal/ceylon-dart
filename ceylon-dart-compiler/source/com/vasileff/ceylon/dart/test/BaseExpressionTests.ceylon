import ceylon.test {
    test
}

shared
class BaseExpressionTests() {

    shared test
    void referenceToStringInitializer() {
        compileAndCompare {
             """
                void run() {
                    value newString1 = String;
                    value newString2 = ({Character*} characters) => String(characters);
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                void $package$run() {
                    $ceylon$language.Callable newString1 = new $ceylon$language.dart$Callable(([$ceylon$language.Iterable characters]) => new $ceylon$language.String(characters));
                    $ceylon$language.Callable newString2 = new $ceylon$language.dart$Callable(([$ceylon$language.Iterable characters]) => new $ceylon$language.String(characters));
                }

                void run() => $package$run();
             """;
        };
    }

    shared test
    void referenceToIntegerInitializer() {
        compileAndCompare {
             """
                void run() {
                    value newInteger = Integer;
                    value five = newInteger(5);
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                void $package$run() {
                    $ceylon$language.Callable newInteger = new $ceylon$language.dart$Callable(([$ceylon$language.Integer integer]) => new $ceylon$language.Integer($ceylon$language.Integer.nativeValue(integer)));
                    $dart$core.int five = $ceylon$language.Integer.nativeValue(newInteger.$delegate$($ceylon$language.Integer.instance(5)) as $ceylon$language.Integer);
                }

                void run() => $package$run();
             """;
        };
    }

    shared test
    void referenceToEntryInitializer() {
        compileAndCompare {
             """
                shared void run() {
                    value newEntry = Entry<String, Destroyable?>;
                    value entry = newEntry("d", null);
                    print(entry);
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                void $package$run() {
                    $ceylon$language.Callable newEntry = new $ceylon$language.dart$Callable(([$dart$core.Object key, $dart$core.Object item]) => new $ceylon$language.Entry(key, item));
                    $ceylon$language.Entry entry = newEntry.$delegate$($ceylon$language.String.instance("d"), null) as $ceylon$language.Entry;
                    $ceylon$language.print(entry);
                }

                void run() => $package$run();
             """;
        };
    }

    shared test
    void packageQualifierToToplevelClass() {
        compileAndCompare {
             """
                class Foo(String s, Destroyable d) {}

                shared void run() {
                    value newFoo1 = Foo;
                    value newFoo2 = package.Foo;
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                class Foo {
                    Foo([$dart$core.String this.s, $ceylon$language.Destroyable this.d]) {}
                    $dart$core.String s;
                    $ceylon$language.Destroyable d;
                }
                void $package$run() {
                    $ceylon$language.Callable newFoo1 = new $ceylon$language.dart$Callable(([$ceylon$language.String s, $ceylon$language.Destroyable d]) => new Foo($ceylon$language.String.nativeValue(s), d));
                    $ceylon$language.Callable newFoo2 = new $ceylon$language.dart$Callable(([$ceylon$language.String s, $ceylon$language.Destroyable d]) => new Foo($ceylon$language.String.nativeValue(s), d));
                }

                void run() => $package$run();
             """;
        };
    }

    shared test
    void referenceToMemberClass() {
        compileAndCompare {
             """
                class C() {
                    class D(String s) {
                    }
                    shared void foo() {
                        value newD1 = D;
                        value newD2 = (String s) => D(s);
                    }
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                class C$D {
                    C $outer$default$C;
                    C$D([C this.$outer$default$C, $dart$core.String this.s]) {}
                    $dart$core.String s;
                }
                class C {
                    C() {}
                    void foo() {
                        $ceylon$language.Callable newD1 = new $ceylon$language.dart$Callable(([$ceylon$language.String s]) => new C$D(this, $ceylon$language.String.nativeValue(s)));
                        $ceylon$language.Callable newD2 = new $ceylon$language.dart$Callable(([$ceylon$language.String s]) => new C$D(this, $ceylon$language.String.nativeValue(s)));
                    }
                }
             """;
        };
    }

    shared test
    void referenceToInnerClassWithCapture() {
        compileAndCompare {
             """
                class C() {
                    void foo() {
                        String captureMe = "";
                        class D(String s) {
                            String useCM => captureMe;
                        }
                        value newD1 = D;
                        value newD2 = (String s) => D(s);
                    }
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                class C$foo$D {
                    C $outer$default$C;
                    $dart$core.String $capture$C$foo$captureMe;
                    C$foo$D([C this.$outer$default$C, $dart$core.String this.$capture$C$foo$captureMe, $dart$core.String this.s]) {}
                    $dart$core.String s;
                    $dart$core.String get useCM => $capture$C$foo$captureMe;
                }
                class C {
                    C() {}
                    void foo() {
                        $dart$core.String captureMe = "";
                        $ceylon$language.Callable newD1 = new $ceylon$language.dart$Callable(([$ceylon$language.String s]) => new C$foo$D(this, captureMe, $ceylon$language.String.nativeValue(s)));
                        $ceylon$language.Callable newD2 = new $ceylon$language.dart$Callable(([$ceylon$language.String s]) => new C$foo$D(this, captureMe, $ceylon$language.String.nativeValue(s)));
                    }
                }
             """;
        };
    }

    shared test
    void referenceToMemberClassTwoOuters() {
        compileAndCompare {
             """
                interface I1 {
                    interface I2 {
                        class C() satisfies I2 {}
                        value newC1 => C;
                        value newC2 => () => C();
                        void foo() {
                            value newC3 => C;
                            value newC4 => () => C();
                        }
                    }
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                class I1$I2$C implements I1$I2 {
                    I1$I2 $outer$default$I1$I2;
                    I1 $outer$default$I1;
                    I1$I2$C([I1$I2 this.$outer$default$I1$I2, I1 this.$outer$default$I1]) {}
                }
                abstract class I1$I2 {
                    I1 $outer$default$I1;
                    static $ceylon$language.Callable $get$newC1([final I1$I2 $this]) => new $ceylon$language.dart$Callable(() => new I1$I2$C($this, $this.$outer$default$I1));
                    static $ceylon$language.Callable $get$newC2([final I1$I2 $this]) => new $ceylon$language.dart$Callable(() => new I1$I2$C($this, $this.$outer$default$I1));
                    static void $foo([final I1$I2 $this]) {
                        $ceylon$language.Callable newC3$get() => new $ceylon$language.dart$Callable(() => new I1$I2$C($this, $this.$outer$default$I1));

                        $ceylon$language.Callable newC4$get() => new $ceylon$language.dart$Callable(() => new I1$I2$C($this, $this.$outer$default$I1));

                    }
                }
                abstract class I1 {
                }
             """;
        };
    }



}
