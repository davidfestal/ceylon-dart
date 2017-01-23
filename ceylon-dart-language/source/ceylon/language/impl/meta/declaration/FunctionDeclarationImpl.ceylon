import ceylon.dart.runtime.model {
    ModelFunction = Function
}
import ceylon.language {
    AnnotationType = Annotation
}
import ceylon.language.meta.declaration {
    FunctionDeclaration
}
import ceylon.language.meta.model {
    ClosedType = Type,
    MemberClass,
    Class,
    Member,
    ClassOrInterface,
    IncompatibleTypeException,
    TypeApplicationException,
    FunctionModel,
    Function,
    Method,
    Qualified
}
import ceylon.language.impl.meta.model {
    modelTypeFromType,
    newType,
    newMethod
}

class FunctionDeclarationImpl(modelDeclaration)
        satisfies FunctionDeclaration {

    shared ModelFunction modelDeclaration;

    object helper satisfies FunctionOrValueDeclarationHelper
                          & FunctionalDeclarationHelper {
        modelDeclaration => outer.modelDeclaration;
    }

    shared actual
    Function<Return,Arguments>
    apply<Return=Anything, Arguments=Nothing>(ClosedType<>* typeArguments)
            given Arguments satisfies Anything[]
        =>  nothing;

    shared
    Method<> memberApplyUnchecked(
            ClosedType<Object> containerType,
            ClosedType<Anything>* typeArguments) {

        if (toplevel) {
            throw TypeApplicationException(
                "Cannot apply a toplevel declaration to a container type: use apply");
        }

        value qualifyingType
            =   getQualifyingSupertypeOrThrow {
                    modelTypeFromType(containerType);
                    modelDeclaration;
                };

        value modelTypeArgs
            =   typeArguments.collect(modelTypeFromType);

        validateTypeArgumentsOrThrow {
            qualifyingType;
            modelDeclaration;
            modelTypeArgs;
        };

        return newMethod {
            modelDeclaration.appliedTypedReference {
                qualifyingType = qualifyingType;
                typeArguments = modelTypeArgs;
                varianceOverrides = emptyMap;
            };
        };
    }

    shared actual
    Method<Container, Return, Arguments>
    memberApply<Container=Nothing, Return=Anything, Arguments=Nothing>
            (ClosedType<Object> containerType, ClosedType<>* typeArguments)
            given Arguments satisfies Anything[] {

        value result = memberApplyUnchecked(containerType, *typeArguments);

        if (!is Method<Container, Return, Arguments> result) {
            // TODO Improve. The JVM code claims to do better with
            //      checkReifiedTypeArgument()
            throw IncompatibleTypeException("Incorrect Container, Return, or Arguments");
        }

        return result;
    }

    // FunctionalDeclaration

    annotation => helper.annotation;

    parameterDeclarations => helper.parameterDeclarations;

    getParameterDeclaration(String name) => getParameterDeclaration(name);

    memberInvoke(Object container, ClosedType<>[] typeArguments, Anything* arguments)
        =>  helper.memberInvoke(container, typeArguments, *arguments);

    // FunctionOrValueDeclaration

    parameter => helper.parameter;
    defaulted => helper.defaulted;
    variadic => helper.variadic;

    // Declaration

    name => helper.name;
    qualifiedName => helper.qualifiedName;

    // GenericDeclaration

    typeParameterDeclarations => helper.typeParameterDeclarations;
    getTypeParameterDeclaration(String name) => helper.getTypeParameterDeclaration(name);

    // NestableDeclaration

    actual => helper.actual;
    container => helper.container;
    containingModule => helper.containingModule;
    containingPackage => helper.containingPackage;
    default => helper.default;
    formal => helper.formal;
    shared => helper.shared;
    toplevel => helper.toplevel;

    // TypedDeclaration

    openType => helper.openType;

    // AnnotatedDeclaration

    shared actual
    Annotation[] annotations<Annotation>()
            given Annotation satisfies AnnotationType
        =>  helper.annotations<Annotation>();

    // Annotated

    shared actual
    Boolean annotated<Annotation>()
            given Annotation satisfies AnnotationType
        =>  helper.annotated<Annotation>();
}