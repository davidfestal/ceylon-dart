import java.lang { System, Long, Double, Int=Integer, Math }

"Represents the machine and virtual machine on which the 
 current process is executing.
 
 Holds information about runtime name, version and about 
 inherent limitations like minimum/maximum values that can 
 be represented by the runtime."
see (`value process`, `value language`, `value system`,
     `value operatingSystem`)
tagged("Environment")
shared native object runtime  {
    
    "The name of the runtime / virtual machine this process 
     is running on."
    shared native String name;
    
    "The version of the runtime / virtual machine this 
     process is running on."
    shared native String version;
    
    "The number of bits used to represent the value of an 
     [[Integer]]."
    see (`class Integer`)
    shared native Integer integerSize;
    
    "The number of bits of [[Integer]] instances which may 
     be manipulated via the methods inherited from
     [[Binary]]."
    shared native Integer integerAddressableSize;
    
    "The smallest [[Integer]] value that can be represented 
     by the runtime.
     
     It is the minimum `Integer` that can be distinguished 
     from its successor using below formula:
     
     `Integer(n-1) = Integer(n) - 1` with `Integer(0) = 0`"
    see (`class Integer`)
    shared native Integer minIntegerValue;

    "The largest [[Integer]] value that can be represented 
     by the runtime.
     
     It is the maximum `Integer` that can be distinguished 
     from its predecessor using below formula:
     
     `Integer(n+1) = Integer(n) + 1` with `Integer(0) = 0`"
    see (`class Integer`)
    shared native Integer maxIntegerValue;
    
    "The maximum size of an [[Array]] that is possible for 
     this runtime. Note that this is a theoretical limit 
     only. In practice it is usually impossible to allocate 
     an array of this size, due to memory constraints."
    see (`class Array`)
    shared native Integer maxArraySize;
    
    "The largest finite [[Float]] value that can be 
     represented by the runtime."
    shared native Float maxFloatValue;

    "The smallest positive nonzero [[Float]] value that can 
     be represented by the runtime."
    shared native Float minFloatValue;
    
    "The _machine epsilon_ for [[floating point|Float]]
     values. That is, the smallest value `e` such that:
     
         1.0 + e > 1.0"
    shared native Float epsilon; 
    
    "The largest [[Integer]] that can be exactly represented
     as a [[Float]] without loss of precision. The negative
     of this value is the smallest `Integer` that can be
     exactly represented as a `Float`."
    see (`value Integer.float`)
    shared native Integer maxExactIntegralFloat;
    
    string => "runtime [``name`` / ``version``]";
}

shared native("jvm") object runtime  {
    shared native("jvm") String name 
            => "jvm";
    shared native("jvm") String version 
            => System.getProperty(
                    "java.specification.version");
    shared native("jvm") Integer integerSize 
            => 64;
    shared native("jvm") Integer integerAddressableSize 
            => 64;
    shared native("jvm") Integer minIntegerValue 
            => Long.minValue;
    shared native("jvm") Integer maxIntegerValue 
            => Long.maxValue;
    shared native("jvm") Integer maxArraySize 
            = Int.maxValue - 8;
    shared native("jvm") Float maxFloatValue 
            => Double.maxValue;
    shared native("jvm") Float minFloatValue 
            => Double.minValue;    
    shared native("jvm") Float epsilon 
            = Math.ulp(1.0);
    shared native("jvm") Integer maxExactIntegralFloat 
            = 2^53-1;
}

shared native("js") object runtime  {
    shared native("js") String name {
        dynamic {
            if (is String version 
                = process.propertyValue("node.version")) {
                return "node.js";
            }
            else if (exists window) {
                return "Browser";
            }
            else {
                return "Unknown JavaScript environment";
            }
        }
    }
    shared native("js") String version {
        dynamic { 
            if (is String version 
                = process.propertyValue("node.version")) {
                return version;
            }
            else if (is String version 
                = process.propertyValue("browser.version")) {
                return version;
            }
            else {
                return "Unknown";
            }
        }
    }
    shared native("js") Integer integerSize => 53;
    shared native("js") Integer integerAddressableSize => 32;
    shared native("js") Integer minIntegerValue = -(2^53-1);
    shared native("js") Integer maxIntegerValue = 2^53-1;
    shared native("js") Integer maxArraySize = 2^32-1;
    shared native("js") Float epsilon = 2.0^(-52);
    shared native("js") Integer maxExactIntegralFloat 
            => maxIntegerValue;
    shared native("js") Float maxFloatValue {
        dynamic {
            return \iNumber.\iMAX_VALUE;
        }
    }
    shared native("js") Float minFloatValue {
        dynamic {
            return \iNumber.\iMIN_VALUE;
        }
    }
}

shared native("dart") object runtime  {
    shared native("dart") String name = "DartVM";
    shared native("dart") String version
        =>  process.propertyValue("platform.version") else "Unknown";
    shared native("dart") Integer integerSize = 53;
    shared native("dart") Integer integerAddressableSize = 32;
    shared native("dart") Integer maxIntegerValue = 2^53 - 1;
    shared native("dart") Integer minIntegerValue = -(2^53-1);
    shared native("dart") Integer maxArraySize = 2^63 - 1;
    shared native("dart") Float maxFloatValue = 1.7976931348623157e+308;

    // FIXME parseCeylonFloat replaces 5.0e-324 with 0.0
    //shared native("dart") Float minFloatValue = 5.0e-324;
    shared native("dart") Float minFloatValue = (() {
        variable value x = 1.0;
        while (x / 2.0 != 0.0) {
            x = x / 2.0;
        }
        return x;
    })();

    shared native("dart") Float epsilon = 2.0^(-52);
    shared native("dart") Integer maxExactIntegralFloat = 2^53-1;
}

