"This module provides:

 - `ceylon.numeric.float`&mdash;various common mathematical
   functions for floating-point numbers, and
 - `ceylon.numeric.integer`&mdash;various common functions for
   integers."
module ceylon.numeric maven:"org.ceylon-lang" "1.3.2" {
    native("jvm") import java.base "7";
    native("dart") import "dart.math" "1.3.2";
}
