import com.vasileff.ceylon.dart.compiler {
    compile
}

shared
void run() {
    value program2 =
           """
              void prog2() {}
           """;
    value program =
           """
              import ceylon.language { myTrue = true, myNull = null }
              \Itrue localTrue = true;
              void main() {
                Integer ii1 = 1;
                Integer? ii2 = 1;
                Integer? ii3 = myNull;
                Object oi1 = 1;
                Object oi2 = ii1;
                Object? oi3 = null;

                Float ff1 = 1.0;
                Float? ff2 = 1.0;
                Object fo1 = 1.0;
                Float|Integer fo2 = 1.0;

                Boolean t1 = myTrue;
                Boolean? t2 = myTrue;
                \Itrue t3 = myTrue;
                \Itrue? t4 = myTrue;
                Boolean|String to1 = myTrue;
                \Itrue|String to2 = myTrue;

                Boolean f1 = false;
                Boolean? f2 = false;
                Boolean? f2n = null;
                \Ifalse f3 = false;
                \Ifalse? f4 = false;
                \Ifalse? f5n = null;
                Boolean|String fob1 = false;
                \Ifalse|String fob2 = false;
              }
           """;
//         """
//            void main() {
//                value x = (Integer t) { print("printing"); return t; };
//                value y = (Integer t) => t;
//
//                // TODO:
//                // value lazyVal => 1;
//
//                helloDart(1);
//                //void sub(String s, Integer i, [String, Float] t = ["asd", 1.0]) { print("xyz"); }
//                void subfd(Float f, String s = "sdef", Integer i = 99) { print("xyz"); }
//                void subsc(Float f, String s = "sdef", Integer i = 99) => print("xyz");
//                Anything subsc2(Float f, String s = "sdef", Integer i = 99) => print("xyz");
//            }
//
//            void helloDart(Integer y) {
//                value n = null;
//                print("Hello Dart!");
//                return;
//            }
//         """;

    compile(program);
}
