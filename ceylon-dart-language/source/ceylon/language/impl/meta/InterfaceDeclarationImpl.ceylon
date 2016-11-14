import ceylon.dart.runtime.model {
    InterfaceModel=Interface
}
import ceylon.language {
    AnnotationType=Annotation
}
import ceylon.language.meta.declaration {
    InterfaceDeclaration,
    NestableDeclaration
}
import ceylon.language.meta.model {
    Interface,
    MemberInterface,
    AppliedType=Type,
    Member,
    ClassOrInterface
}

shared
class InterfaceDeclarationImpl(delegate)
        extends ClassOrInterfaceDeclarationImpl()
        satisfies InterfaceDeclaration {

    shared actual InterfaceModel delegate;

    shared actual Interface<Type> interfaceApply<Type=Anything>
            (AppliedType<>* typeArguments)
        =>  nothing;

    shared actual MemberInterface<Container, Type> memberInterfaceApply
            <Container=Nothing, Type=Anything>
            (AppliedType<Object> containerType, AppliedType<>* typeArguments)
        =>  nothing;

    string => "interface ``qualifiedName``";

    // FROM ClassOrInterfaceDeclaration

    caseTypes => caseTypesImpl;
    extendedType => extendedTypeImpl;
    isAlias => isAliasImpl;
    satisfiedTypes => satisfiedTypesImpl;

    shared actual Kind[] annotatedDeclaredMemberDeclarations<Kind, Annotation>()
            given Kind satisfies NestableDeclaration
            given Annotation satisfies AnnotationType
        =>  annotatedDeclaredMemberDeclarationsImpl<Kind, Annotation>();

    shared actual Kind[] annotatedMemberDeclarations<Kind, Annotation>()
            given Kind satisfies NestableDeclaration
            given Annotation satisfies AnnotationType
        =>  annotatedMemberDeclarationsImpl<Kind, Annotation>();

    shared actual ClassOrInterface<Type> apply<Type>
            (AppliedType<Anything>* typeArguments)
        =>  applyImpl<Type>(*typeArguments);

    shared actual Kind[] declaredMemberDeclarations<Kind>()
            given Kind satisfies NestableDeclaration
        =>  declaredMemberDeclarationsImpl<Kind>();

    shared actual Kind? getDeclaredMemberDeclaration<Kind>(String name)
            given Kind satisfies NestableDeclaration
        =>  getDeclaredMemberDeclarationImpl<Kind>(name);

    shared actual Kind? getMemberDeclaration<Kind>(String name)
            given Kind satisfies NestableDeclaration
        =>  getMemberDeclarationImpl<Kind>(name);

    shared actual Member<Container,ClassOrInterface<Type>>&ClassOrInterface<Type>
    memberApply<Container, Type>(
            AppliedType<Object> containerType,
            AppliedType<Anything>* typeArguments)
        =>  memberApplyImpl<Container, Type>(containerType, *typeArguments);

    shared actual Kind[] memberDeclarations<Kind>()
            given Kind satisfies NestableDeclaration
        =>  memberDeclarationsImpl<Kind>();

    // FROM Declaration

    name => nameImpl;
    qualifiedName => qualifiedNameImpl;

    // FROM GenericDeclaration

    typeParameterDeclarations => typeParameterDeclarationsImpl;
    getTypeParameterDeclaration(String name) => getTypeParameterDeclarationImpl(name);

    // FROM NestableDeclaration

    actual => actualImpl;
    container => containerImpl;
    containingModule => containingModuleImpl;
    containingPackage => containingPackageImpl;
    default => defaultImpl;
    formal => formalImpl;
    shared => sharedImpl;
    toplevel => toplevelImpl;

    // FROM TypedDeclaration

    openType => openTypeImpl;

    // FROM AnnotatedDeclaration

    shared actual Annotation[] annotations<Annotation>()
            given Annotation satisfies AnnotationType
        =>  annotationsImpl<Annotation>();

    // FROM Annotated

    shared actual Boolean annotated<Annotation>()
            given Annotation satisfies AnnotationType
        =>  annotatedImpl<Annotation>();
}
