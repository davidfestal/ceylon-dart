import ceylon.test {
    test,
    ignore
}

shared
class AssignmentTests() {

    shared test ignore
    void assignExpressionNativeString() {
         compileAndCompare {
             """
                interface SomeInt {
                    shared formal variable String someString;
                }

                void run(SomeInt si) {
                    value x = si.someString = "";
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                abstract class SomeInt {
                    $dart$core.String get someString;
                    set someString($dart$core.String $newValue);
                }
                void $package$run([SomeInt si]) {
                    $dart$core.String x = si.someString = "";
                }

                void run([SomeInt si]) => $package$run(si);
             """;
        };
    }

    shared test ignore
    void assignExpressionRhsCast() {
        // TODO remove unnecessary cast; see generateAssignmentExpression comments
        compileAndCompare {
             """
                interface SomeInt {
                    shared formal variable Object someObject;
                }

                void run(SomeInt si) {
                    value y = si.someObject = "";
                }
             """;

             """
                import "dart:core" as $dart$core;
                import "package:ceylon/language/language.dart" as $ceylon$language;

                abstract class SomeInt {
                    $dart$core.Object get someObject;
                    set someObject($dart$core.Object $newValue);
                }
                void $package$run([SomeInt si]) {
                    $dart$core.String y = $ceylon$language.String.nativeValue((si.someObject = $ceylon$language.String.instance("")) as $ceylon$language.String);
                }

                void run([SomeInt si]) => $package$run(si);
             """;
        };
    }

}