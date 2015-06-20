import com.redhat.ceylon.model.typechecker.model {
    Type,
    Unit,
    ModelUtil,
    Declaration
}
import com.vasileff.jl4c.guava.collect {
    javaList
}

class TypeFactory(Unit unit) {

    /////////////////////////////////////////////
    // common types
    /////////////////////////////////////////////

    shared
    Type anythingType => unit.anythingType;

    shared
    Type nullType => unit.nullType;

    shared
    Type objectType => unit.objectType;

    shared
    Type booleanType => unit.booleanType;

    shared
    Type byteType => unit.byteType;

    shared
    Type characterType => unit.characterType;

    shared
    Type floatType => unit.floatType;

    shared
    Type integerType => unit.integerType;

    shared
    Type stringType => unit.stringType;

    shared
    Type nothingType => unit.nothingType;

    /////////////////////////////////////////////
    // Boolean isCeylonX(type)
    /////////////////////////////////////////////

    shared
    Boolean isCeylonNull(Type type)
        // Null, \Inull, but not Nothing
        =>  !type.nothing && type.isSubtypeOf(nullType);

    shared
    Boolean isCeylonObject(Type type)
        =>  type.isExactly(objectType);

    shared
    Boolean isCeylonBoolean(Type type)
        // Boolean, \Itrue, \Ifalse
        =>  !type.nothing && type.isSubtypeOf(booleanType);

    shared
    Boolean isCeylonOptionalBoolean(Type type)
        // Boolean, \Itrue, \Ifalse, \Inull, Null
        =>  !type.nothing &&
                intersection(type, objectType)
                .isSubtypeOf(booleanType);

    shared
    Boolean isCeylonByte(Type type)
        =>  type.isExactly(byteType);

    shared
    Boolean isCeylonCharacter(Type type)
        =>  type.isExactly(characterType);

    shared
    Boolean isCeylonFloat(Type type)
        =>  type.isExactly(floatType);

    shared
    Boolean isCeylonInteger(Type type)
        =>  type.isExactly(integerType);

    shared
    Boolean isCeylonString(Type type)
        =>  type.isExactly(stringType);

    shared
    Boolean isCeylonNothing(Type type)
        =>  type.isExactly(nothingType);

    /////////////////////////////////////////////
    // common declarations
    /////////////////////////////////////////////

    // not sure about the safety implications due
    // to duplicate instances re:
    // https://github.com/ceylon/ceylon-compiler/issues/1815

    Declaration booleanTrueDeclaration
        =>  unit.getLanguageModuleDeclaration("true");

    Declaration booleanFalseDeclaration
        =>  unit.getLanguageModuleDeclaration("false");

    Declaration nullDeclaration
        =>  unit.getLanguageModuleDeclaration("null");

    shared
    Declaration assertionErrorDeclaration
        =>  unit.getLanguageModuleDeclaration("AssertionError");

    /////////////////////////////////////////////
    // declaration tests
    /////////////////////////////////////////////

    shared
    Boolean isBooleanTrueDeclaration(Declaration declaration)
        =>  equalDeclarations(declaration, booleanTrueDeclaration);

    shared
    Boolean isBooleanFalseDeclaration(Declaration declaration)
        =>  equalDeclarations(declaration, booleanFalseDeclaration);

    shared
    Boolean isNullDeclaration(Declaration declaration)
        =>  equalDeclarations(declaration, nullDeclaration);

    /////////////////////////////////////////////
    // utilities
    /////////////////////////////////////////////

    shared
    Type intersection(Type *types)
        =>  ModelUtil.intersection(javaList(types), unit);

    shared
    Type union(Type *types)
        =>  ModelUtil.union(javaList(types), unit);

    shared
    Boolean equalDeclarations(Declaration first, Declaration second)
        =>  ModelUtil.equal(first, second);

    /////////////////////////////////////////////
    // boxing
    /////////////////////////////////////////////

    shared
    BoxingConversion? boxingConversionFor(
            Type lhs, Type rhs) {

        // NOTE: we are assuming from and to are not any of the
        // exceptional cases, such as type parameters or actual
        // refinements of formal methods and attributes

        // assigments to or from null don't need conversion
        // (they will be the null value)
        if (isCeylonNull(rhs) || isCeylonNull(lhs)) {
            return null;
        }

        value intersectedLhs = intersection(
                objectType, lhs);

        value intersectedRhs = intersection(
                objectType, rhs);

        // obvious case
        if (intersectedLhs.isExactly(intersectedRhs)) {
            return null;
        }

        // for cases below that are final classes, we don't
        // need to re-check the "other" type; we already know
        // "lhs" and "rhs" are not exactly the same

        // to Ceylon conversions
        if (isCeylonBoolean(intersectedRhs)) {
            return !isCeylonBoolean(intersectedLhs)
                    then nativeToCeylonBoolean;
        }
        else if (isCeylonFloat(intersectedRhs)) {
            return nativeToCeylonFloat;
        }
        else if (isCeylonInteger(intersectedRhs)) {
            return nativeToCeylonInteger;
        }
        else if (isCeylonString(intersectedRhs)) {
            return nativeToCeylonString;
        }

        // to native conversions
        if (isCeylonBoolean(intersectedLhs)) {
            return !isCeylonBoolean(intersectedRhs)
                    then ceylonBooleanToNative;
        }
        else if (isCeylonFloat(intersectedLhs)) {
            return ceylonFloatToNative;
        }
        else if (isCeylonInteger(intersectedLhs)) {
            return ceylonIntegerToNative;
        }
        else if (isCeylonString(intersectedLhs)) {
            return ceylonStringToNative;
        }
        return null;
    }
}
