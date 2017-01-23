import ceylon.language.meta.model {
    ClosedType = Type
}
import ceylon.dart.runtime.model {
    ModelTypedReference = TypedReference,
    ModelType = Type
}
import ceylon.language.impl.meta.declaration {
    newClassDeclaration
}

interface FunctionModelHelper<out Type, in Arguments>
        satisfies GenericHelper
        given Arguments satisfies Anything[] {

    // shared actual formal
    // ModelTypedReference modelType;

    shared
    ClosedType<Type> type
        =>  switch (modelType = this.modelType)
            case (is ModelTypedReference) // function or method
                newType<Type>(modelType.type)
            case (is ModelType) // constructor
                newType<Type>(modelType);

    // Functional

    shared
    ClosedType<>[] parameterTypes => nothing;
}