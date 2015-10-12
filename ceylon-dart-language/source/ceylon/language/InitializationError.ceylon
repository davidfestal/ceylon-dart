"[[Assertion failure|AssertionError]] that occurs when a 
 value reference could not be initialized, including when:
 
 - a toplevel value could not be initialized due to 
   recursive dependencies upon other toplevel values, 
 - an uninitialized [[late]] value is evaluated, 
 - an initialized `late` but non-`variable` value is
   reassigned."
see (`function late`)
shared class InitializationError(String description)
        extends AssertionError(description) {}
