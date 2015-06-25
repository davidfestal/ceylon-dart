import ceylon.collection {
    HashMap
}
import ceylon.interop.java {
    CeylonIterable
}

import com.redhat.ceylon.model.typechecker.model {
    DeclarationModel=Declaration,
    TypedDeclarationModel=TypedDeclaration,
    FunctionModel=Function,
    ClassModel=Class,
    InterfaceModel=Interface,
    ValueModel=Value,
    ElementModel=Element,
    UnitModel=Unit,
    ModuleModel=Module,
    SetterModel=Setter,
    ParameterModel=Parameter,
    TypeModel=Type
}

class Naming(TypeFactory typeFactory) {

    variable value counter = 0;

    value nameCache = HashMap<TypedDeclarationModel, String>();

    shared
    String getName(DeclarationModel|ParameterModel declaration) {
        if (is SetterModel declaration) {
            getName(declaration.getter);
        }

        if (is TypedDeclarationModel declaration) {
            // search for replacement name
            variable value model = declaration;
            while (true) {
                if (exists name = nameCache[declaration]) {
                    return name;
                }
                if (exists parent = model.originalDeclaration) {
                    model = parent;
                    continue;
                }
                break;
            }
        }

        switch (declaration)
        case (is ValueModel) {
            return declaration.name;
        }
        case (is FunctionModel) {
            return (declaration of DeclarationModel).name;
        }
        case (is ClassModel) {
            return (declaration of DeclarationModel).name;
        }
        case (is InterfaceModel) {
            return (declaration of DeclarationModel).name;
        }
        case (is ParameterModel) {
            return declaration.name;
        }
        else {
            throw Exception("declaration type not yet supported \
                             for ``className(declaration)``");
        }
    }

    shared
    String createReplacementName(TypedDeclarationModel declaration) {
        if (is SetterModel declaration) {
            return createReplacementName(declaration.getter);
        }

        String replacement;
        switch (declaration)
        case (is ValueModel) {
            replacement = declaration.name + "$" + (counter++).string;
        }
        else {
            throw Exception("declaration type not yet supported \
                             for ``className(declaration)``");
        }
        nameCache.put(declaration, replacement);
        return replacement;
    }

    shared
    String createTempName(TypedDeclarationModel declaration) {
        return declaration.name + "$" + (counter++).string;
    }

    "The Dart library prefix for the Ceylon module."
    shared
    String moduleImportPrefix
            (ElementModel|UnitModel|ModuleModel declaration);

    moduleImportPrefix
        =   memoize((ElementModel|UnitModel|ModuleModel declaration)
            =>  CeylonIterable(getModule(declaration).name)
                    .map(Object.string)
                    .interpose("$")
                    .fold("$")(plus));

    "The prefix to use for identifiers to simulate Ceylon packages
     in Dart. This is the part of the Ceylon package name that is not
     part of the containing module's base package, with `.` replaced
     by `$`, and a trailing `$` if nonempty."
    shared
    String identifierPackagePrefix
            (ElementModel|UnitModel declaration);

    identifierPackagePrefix
        =   memoize((ElementModel|UnitModel declaration)
            =>  CeylonIterable(getPackage(declaration).name)
                    .skip(getModule(declaration).name.size())
                    .map(Object.string)
                    .interpose("$")
                    .reduce(plus)
                    ?.plus("$") else "");

    shared
    DartTypeName dartObject
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("Object");
                };
            };

    shared
    DartTypeName dartBool
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("bool");
                };
            };

    shared
    DartTypeName dartInt
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("int");
                };
            };

    shared
    DartTypeName dartDouble
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("double");
                };
            };

    shared
    DartTypeName dartFunction
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("Function");
                };
            };

    shared
    DartTypeName dartString
        =   DartTypeName {
                DartPrefixedIdentifier {
                    DartSimpleIdentifier("$dart$core");
                    DartSimpleIdentifier("String");
                };
            };

    see(`function TypeFactory.boxingConversionFor`) // erasureFor?
    shared
    DartTypeName dartTypeName
            (ElementModel inRelationTo, TypeModel type) {

        // TODO add tests for non-boxed types

        // TODO document/explore erasure for generics
        //      and also for covariant returns. Can the
        //      caller always just use the `formal`,
        //      non-refined type? Is it readily available?

        // TODO we erase Object & Basic here, but need to
        //      address boxing/erasure issues elsewhere, like
        //      method invocations

        value definiteType = typeFactory.definiteType(type);

        // handle well known types first, before giving up
        // on unions and intersections
        if (typeFactory.isCeylonBoolean(definiteType)) {
            return dartBool;
        }
        else if (typeFactory.isCeylonInteger(definiteType)) {
            return dartInt;
        }
        else if (typeFactory.isCeylonFloat(definiteType)) {
            return dartDouble;
        }
        else if (typeFactory.isCeylonString(definiteType)) {
            return dartString;
        }
        else if (typeFactory.isCeylonAnything(definiteType)) {
            return dartObject;
        }
        else if (typeFactory.isCeylonNothing(definiteType)) {
            // this handles the `Null` case too,
            // since Null & Object = Nothing
            return dartObject;
        }
        else if (typeFactory.isCeylonObject(definiteType)) {
            return dartObject;
        }
        else if (typeFactory.isCeylonBasic(definiteType)) {
            return dartObject;
        }
        else if (typeFactory.isCeylonCallable(definiteType)) {
            // FIXME only erase to function when the types match exactly
            //       The plan is to box as soon as we lose
            //       exact generic type info. So we need the
            //       original type for the comparison; comparing to
            //       Callable<Anything, Nothing> isn't good enough.
            //       We could just always box, but then we'll have to
            //       worry about optimizing function expressions.
            return dartFunction;
        }
        else if (definiteType.union || definiteType.intersection) {
            // settle for Object for other unions and intersections
            return dartObject;
        }
        else {
            // finally, just regular, unerased, unboxed types
            if (sameModule(inRelationTo, definiteType.declaration)) {
                return
                DartTypeName {
                    DartSimpleIdentifier(
                        identifierPackagePrefix(definiteType.declaration) +
                        getName(definiteType.declaration));
                };
            }
            else {
                return
                DartTypeName {
                    DartPrefixedIdentifier {
                        DartSimpleIdentifier {
                            moduleImportPrefix(definiteType.declaration);
                        };
                        DartSimpleIdentifier {
                            identifierPackagePrefix(definiteType.declaration) +
                                getName(definiteType.declaration);
                        };
                    };
                };
            }
        }
    }
}

Result memoize<Result, Argument>
        (Result compute(Argument argument),
         HashMap<Argument, Result> cache =
                HashMap<Argument, Result>())
        (Argument argument)
        given Argument satisfies Object
        given Result satisfies Object {
    if (exists result = cache.get(argument)) {
        return result;
    }
    else {
        value result = compute(argument);
        cache.put(argument, result);
        return result;
    }
}