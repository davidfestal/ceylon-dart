import ceylon.test {
    test
}

shared test
void parameterReferenceTest() {
    compileAndCompare {
         """
            void foo(arg1, arg2=5, arg3="v3") {
                String arg1;
                Integer arg2;
                String arg3;
            }
         """;

         """
            import "dart:core" as $dart$core;
            import "package:ceylon/language/language.dart" as $ceylon$language;

            void $package$foo([$dart$core.String arg1, $dart$core.Object arg2 = $ceylon$language.dart$default, $dart$core.Object arg3 = $ceylon$language.dart$default]) {
                if ($dart$core.identical(arg2, $ceylon$language.dart$default)) {
                    arg2 = 5;
                }
                if ($dart$core.identical(arg3, $ceylon$language.dart$default)) {
                    arg3 = "v3";
                }
            }

            void foo([$dart$core.String arg1, $dart$core.Object arg2 = $ceylon$language.dart$default, $dart$core.Object arg3 = $ceylon$language.dart$default]) => $package$foo(arg1, arg2, arg3);
         """;
    };
}