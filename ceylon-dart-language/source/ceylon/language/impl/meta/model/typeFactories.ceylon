import ceylon.language.meta.model {
    ClosedType = Type, Class, MemberClass, Interface, MemberInterface, UnionType,
    InterfaceModel, CallableConstructor, ValueConstructor, ClassModel,
    MemberClassCallableConstructor, MemberClassValueConstructor,
    IntersectionType, nothingType,
    Function, Method, Value, Attribute
}
import ceylon.dart.runtime.model {
    ModelReference = Reference,
    ModelType = Type,
    ModelTypedReference = TypedReference,
    ModelClass = Class,
    ModelClassDefinition = ClassDefinition,
    ModelClassWithInitializer = ClassWithInitializer,
    ModelConstructor = Constructor,
    ModelValueConstructor = ValueConstructor,
    ModelCallableConstructor = CallableConstructor,
    ModelTypeAlias = TypeAlias,
    ModelTypeParameter = TypeParameter,
    ModelInterface = Interface,
    ModelPackage = Package,
    ModelUnknownType = UnknownType,
    ModelValue = Value,
    ModelUnionType = UnionType,
    ModelIntersectionType = IntersectionType,
    ModelNothingDeclaration = NothingDeclaration
}
import ceylon.dart.runtime.model.runtime {
    TypeDescriptor,
    TypeDescriptorImpl
}

shared CallableConstructor<> newCallableConstructor
        (ModelType modelType, Anything qualifyingInstance)
    =>  let ([returnType, argumentsTuple] = returnTypeAndArguments(modelType))
        createCallableConstructor {
            typeTP = TypeDescriptorImpl(returnType);
            argumentsTP = TypeDescriptorImpl(argumentsTuple);
            modelType = modelType;
            qualifyingInstance = qualifyingInstance;
        };

shared MemberClassCallableConstructor<> newMemberClassCallableConstructor
        (ModelType modelType) {
    assert (exists qualifyingType = modelType.qualifyingType?.qualifyingType);
    return let ([returnType, argumentsTuple] = returnTypeAndArguments(modelType))
        createMemberClassCallableConstructor {
            containerTP = TypeDescriptorImpl(qualifyingType);
            typeTP = TypeDescriptorImpl(returnType);
            argumentsTP = TypeDescriptorImpl(argumentsTuple);
            modelType = modelType;
        };
}

shared ValueConstructor<> newValueConstructor
        (ModelType modelType, Anything qualifyingInstance)
    =>  createValueConstructor {
            typeTP = TypeDescriptorImpl(modelType);
            modelType = modelType;
            qualifyingInstance = qualifyingInstance;
        };

shared MemberClassValueConstructor<> newMemberClassValueConstructor
        (ModelType modelType) {
    assert (exists qualifyingType = modelType.qualifyingType?.qualifyingType);
    return createMemberClassValueConstructor {
            containerTP = TypeDescriptorImpl(qualifyingType);
            typeTP = TypeDescriptorImpl(modelType);
            modelType = modelType;
        };
}

shared Value<> newValue(ModelTypedReference modelReference, Anything qualifyingInstance)
    =>  let (typeTD = TypeDescriptorImpl(modelReference.type))
        createValue {
            getTP = typeTD;
            setTP = if (isVariableOrHasSetter(modelReference))
                    then typeTD
                    else TypeDescriptorImpl(
                        modelReference.declaration.unit.getNothingType());
            modelType = modelReference;
            qualifyingInstance = qualifyingInstance;
        };

shared Attribute<> newAttribute(ModelTypedReference modelReference) {
    assert (exists qualifyingType = modelReference.qualifyingType);
    value typeTD = TypeDescriptorImpl(modelReference.type);
    return createAttribute {
        containerTP = TypeDescriptorImpl(qualifyingType);
        getTP = typeTD;
        setTP = if (isVariableOrHasSetter(modelReference))
                then typeTD
                else TypeDescriptorImpl(
                    modelReference.declaration.unit.getNothingType());
        modelType = modelReference;
    };
}

shared Function<> newFunction
        (ModelTypedReference modelReference, Anything qualifyingInstance)
    =>  let ([returnType, argumentsTuple] = returnTypeAndArguments(modelReference))
        createFunction {
            TypeDescriptorImpl(returnType);
            TypeDescriptorImpl(argumentsTuple);
            modelReference;
            qualifyingInstance;
        };

shared Method<> newMethod(ModelTypedReference modelReference) {
    assert (exists containerType = modelReference.qualifyingType);
    return let ([returnType, argumentsTuple] = returnTypeAndArguments(modelReference))
        createMethod {
            TypeDescriptorImpl(containerType);
            TypeDescriptorImpl(returnType);
            TypeDescriptorImpl(argumentsTuple);
            modelReference;
        };
}

shared Class<> newClass(ModelType | TypeDescriptor type, Anything qualifyingInstance)
    =>  let (modelType = if (is TypeDescriptor type) then type.type else type)
        createClass {
            typeTP = TypeDescriptorImpl(modelType);
            argumentsTP = TypeDescriptorImpl(argumentsTupleForClass(modelType));
            modelType = modelType;
            // not validating the container instance
            qualifyingInstance = qualifyingInstance;
        };

shared MemberClass<> newMemberClass(ModelType | TypeDescriptor type) {
    value modelType = if (is TypeDescriptor type) then type.type else type;

    "A member class must have a qualifying type."
    assert (exists qualifyingTypeModel = modelType.qualifyingType);

    return
    createMemberClass {
        containerTP = TypeDescriptorImpl(qualifyingTypeModel);
        typeTP = TypeDescriptorImpl(modelType);
        argumentsTP = TypeDescriptorImpl(argumentsTupleForClass(modelType));
        modelType = modelType;
    };
}

shared Interface<> newInterface
        (ModelType | TypeDescriptor type, Anything qualifyingInstance)
    =>  let (modelType = if (is TypeDescriptor type) then type.type else type)
        createInterface {
            typeTP = TypeDescriptorImpl(modelType);
            modelType = modelType;
            qualifyingInstance = qualifyingInstance;
        };

shared MemberInterface<> newMemberInterface(ModelType | TypeDescriptor type) {
    value modelType = if (is TypeDescriptor type) then type.type else type;
    assert (exists qualifyingType = modelType.qualifyingType);
    return  createMemberInterface {
        containerTP = TypeDescriptorImpl(qualifyingType);
        typeTP = TypeDescriptorImpl(modelType);
        modelType = modelType;
    };
}

shared UnionType<> newUnionType(ModelType | TypeDescriptor type)
    =>  let (modelType = if (is TypeDescriptor type) then type.type else type)
        createUnionType {
            typeTP = TypeDescriptorImpl(modelType);
            modelType = modelType;
        };

shared IntersectionType<> newIntersectionType(ModelType | TypeDescriptor type)
    =>  let (modelType = if (is TypeDescriptor type) then type.type else type)
        createIntersectionType {
            typeTP = TypeDescriptorImpl(modelType);
            modelType = modelType;
        };

shared ClassModel<> newClassModel(ModelType modelType)
    =>  if (modelType.declaration.isMember)
        then newMemberClass(modelType)
        else newClass(modelType, null);

shared InterfaceModel<> newInterfaceModel(ModelType modelType)
    =>  if (modelType.declaration.isMember)
        then newMemberInterface(modelType)
        else newInterface(modelType, null);

"Return the ceylon metamodel type for the type."
shared ClosedType<> newType(ModelType | TypeDescriptor type) {
    value modelType
        =   if (is TypeDescriptor type)
            then type.type
            else type;

    switch (d = modelType.declaration)
    case (is ModelClass) {
        return newClassModel(modelType);
    }
    case (is ModelInterface) {
        return newInterfaceModel(modelType);
    }
    case (is ModelUnionType) {
        return newUnionType(modelType);
    }
    case (is ModelIntersectionType) {
        return newIntersectionType(modelType);
    }
    case (is ModelNothingDeclaration) {
        return nothingType;
    }
    case (is ModelConstructor) {
        throw AssertionError(
            "Constructors are not supported; use newConstructor() instead.");
    }
    case (is ModelTypeAlias | ModelUnknownType | ModelTypeParameter) {
        throw AssertionError(
            "Meta expressions not yet supported for type declaration type: \
            ``className(d)``");
    }
}

MemberClassCallableConstructor<> | MemberClassValueConstructor<>
newMemberClassConstructor(ModelType modelType) {
    "must be constructor for a member class (use newConstructor())"
    assert(modelType.declaration.container is ModelClass);

    switch (d = modelType.declaration)
    case (is ModelValueConstructor) {
        return newMemberClassValueConstructor(modelType);
    }
    case (is ModelCallableConstructor) {
        return newMemberClassCallableConstructor(modelType);
    }
    case (is ModelClass | ModelInterface | ModelUnionType | ModelIntersectionType |
                ModelNothingDeclaration | ModelTypeAlias | ModelUnknownType |
                ModelTypeParameter) {
        throw AssertionError(
            "Argument does not represent a constructor; use newType() instead.");
    }
}

CallableConstructor<> | ValueConstructor<> newConstructor
        (ModelType modelType, Anything qualifyingInstance) {

    "A containing instance must be provided xor the constructor must be for a
     toplevel class"
    assert(qualifyingInstance exists
        != modelType.declaration.container.container is ModelPackage);

    switch (d = modelType.declaration)
    case (is ModelValueConstructor) {
        return newValueConstructor(modelType, qualifyingInstance);
    }
    case (is ModelCallableConstructor) {
        return newCallableConstructor(modelType, qualifyingInstance);
    }
    case (is ModelClass | ModelInterface | ModelUnionType | ModelIntersectionType |
                ModelNothingDeclaration | ModelTypeAlias | ModelUnknownType |
                ModelTypeParameter) {
        throw AssertionError(
            "Argument does not represent a constructor; use newType() instead.");
    }
}

[ModelType, ModelType] returnTypeAndArguments
        (ModelReference modelReference) {
    // Note: For constructors, the return type's declaration is the constructor and the
    //       extended type is the class, which is a bit weird, but ok since usually used
    //       for the covariant `Type` TA?
    value callableType = modelReference.fullType;
    assert (exists result = callableType.unit.getCallableReturnAndTuple(callableType));
    return result;
}

Boolean isVariableOrHasSetter(ModelTypedReference modelReference)
    =>  if (is ModelValue v = modelReference.declaration)
        then v.isVariable || v.setter exists
        else false;

ModelType argumentsTupleForClass(ModelType modelType) {
    assert (is ModelClassDefinition modelDeclaration = modelType.declaration);
    if (is ModelClassWithInitializer modelDeclaration) {
        assert (exists t = modelType.unit.getCallableTuple(modelType.fullType));
        return t;
    }
    else if (is ModelConstructor defaultCtor = modelDeclaration.getDirectMember(""),
             defaultCtor.isShared) {
        assert (exists t = modelType.unit.getCallableTuple {
            defaultCtor.appliedType(modelType, [], emptyMap);
        });
        return t;
    }
    else {
        return modelType.unit.getNothingType();
    }
}

native
Function<> createFunction(
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelTypedReference modelType,
        Anything qualifyingInstance);

native
Method<> createMethod(
        TypeDescriptor containerTP,
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelTypedReference modelType);

native
Value<> createValue(
        TypeDescriptor getTP,
        TypeDescriptor setTP,
        ModelTypedReference modelType,
        Anything qualifyingInstance);

native
Attribute<> createAttribute(
        TypeDescriptor containerTP,
        TypeDescriptor getTP,
        TypeDescriptor setTP,
        ModelTypedReference modelType);

native
CallableConstructor<> createCallableConstructor(
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelType modelType,
        Anything qualifyingInstance);

native
Class<> createClass(
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelType modelType,
        Anything qualifyingInstance);

native
Interface<> createInterface(
        TypeDescriptor typeTP,
        ModelType modelType,
        Anything qualifyingInstance);

native
IntersectionType<> createIntersectionType(
        TypeDescriptor typeTP,
        ModelType modelType);

native
MemberClass<> createMemberClass(
        TypeDescriptor containerTP,
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelType modelType);

native
MemberInterface<> createMemberInterface(
        TypeDescriptor containerTP,
        TypeDescriptor typeTP,
        ModelType modelType);

native
MemberClassCallableConstructor<>
createMemberClassCallableConstructor(
        TypeDescriptor containerTP,
        TypeDescriptor typeTP,
        TypeDescriptor argumentsTP,
        ModelType modelType);

native
MemberClassValueConstructor<> createMemberClassValueConstructor(
        TypeDescriptor containerTP,
        TypeDescriptor typeTP,
        ModelType modelType);

native
UnionType<> createUnionType(
        TypeDescriptor typeTP,
        ModelType modelType);

native
ValueConstructor<> createValueConstructor(
        TypeDescriptor typeTP,
        ModelType modelType,
        Anything qualifyingInstance);
