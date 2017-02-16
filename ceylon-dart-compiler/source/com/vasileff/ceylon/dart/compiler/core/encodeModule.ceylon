import ceylon.collection {
    HashMap
}
import ceylon.interop.java {
    CeylonIterable
}

import com.redhat.ceylon.model.typechecker.model {
    ClassModel=Class,
    ConstructorModel=Constructor,
    TypeModel=Type,
    TypeAliasModel=TypeAlias,
    DeclarationModel=Declaration,
    ModuleModel=Module,
    PackageModel=Package,
    InterfaceModel=Interface,
    TypeParameterModel=TypeParameter,
    TypeDeclarationModel=TypeDeclaration,
    ModelUtil,
    ParameterListModel=ParameterList,
    ParameterModel=Parameter,
    ValueModel=Value,
    FunctionModel=Function
}
import com.vasileff.ceylon.dart.compiler {
    dartBackend
}

shared String keyClasses       = "$c";
shared String keyInterfaces    = "$i";
shared String keyObjects       = "$o";
shared String keyMethods       = "$m";
shared String keyCompositeType = "comp";
shared String keyAttributes    = "$at";
shared String keyAnnotations   = "an";
shared String keyPackedAnnotations = "pa";
shared String keyType          = "$t";
shared String keyReturnType    = "$rt";
shared String keyTypes         = "l";
shared String keyTypeArgs      = "ta";
shared String keyTypeParams    = "tp";
shared String keyMetatype      = "mt";
shared String keyModule        = "md";
shared String keyModuleName    = "$mod-name";
shared String keyModuleVersion = "$mod-version";
shared String keyModuleAnnotations = "$mod-anns";
shared String keyPackageAnnotations = "$pkg-anns";
shared String keyPackagePA     = "$pkg-pa";
shared String keyName          = "nm";
shared String keyPackage       = "pk";
shared String keyParams        = "ps";
shared String keySelfType      = "st";
shared String keySatisfies     = "sts";
shared String keyExtendedType  = "super";
shared String keyDsVariance    = "dv"; //declaration-site variance
shared String keyUsVariance    = "uv"; //use-site variance
shared String keyCases         = "of";
shared String keyConstructors  = "$cn";
shared String keyFlags         = "$ff";
shared String keySetter        = "$set";
shared String keyAlias         = "$alias";

shared String keyDefault       = "def";
shared String keySequenced     = "seq";
shared String keyNamed         = "nam";
shared String keyDynamic       = "dyn";
shared String keyStatic        = "sta";

shared String keyNativeDart     = "$mod-native-dart";

shared String typeUnion         = "u";
shared String typeIntersection  = "i";
shared String typeUnknown       = "$U";

shared String metatypeClass           = "c";
shared String metatypeInterface       = "i";
shared String metatypeAlias           = "als";
shared String metatypeObject          = "o";
shared String metatypeMethod          = "m";
shared String metatypeAttribute       = "a";
shared String metatypeGetter          = "g";
shared String metatypeSetter          = "s";
shared String metatypeTypeParameter   = "tp";
shared String metatypeParameter       = "prm";

shared Set<String> packedAnnotations = set {
    "shared", "actual", "formal", "default", "sealed", "final", "native", "late",
    "abstract", "annotation", "variable", "serializable", "static"
};

shared Integer sharedBit = 0;
shared Integer actualBit = 1;
shared Integer formalBit = 2;
shared Integer defaultBit = 3;
shared Integer sealedBit = 4;
shared Integer finalBit = 5;
shared Integer nativeBit = 6;
shared Integer lateBit = 7;
shared Integer abstractBit = 8;
shared Integer annotationBit = 9;
shared Integer variableBit = 10;
shared Integer serializableBit = 11;
shared Integer staticBit = 12;

shared
Map<String, Object> encodeModule(ModuleModel mod) {
    value m = HashMap<String, Object>();
    m.put(keyModuleName, mod.nameAsString);
    m.put(keyModuleVersion, mod.version);
    m.putAll(encodeAnnotations(mod));
    // TODO $mod-bin: binary version
    // TODO $mod-nat: backends for native modules
    // TODO imports

    // packages
    for (pkg in mod.packages) {
        m.put(pkg.nameAsString, encodePackage(pkg));
    }
    return m;
}

Map<String, Object> encodePackage(PackageModel pkg) {
    value m = HashMap<String, Object>();
    m.putAll(encodeAnnotations(pkg));

    for (member in {*pkg.members}.filter(interestingDeclaration)) {
        if (is ValueModel member,
                is ClassModel typeDeclaration = member.type.declaration,
                typeDeclaration.anonymous,
                typeDeclaration.name == member.name,
                typeDeclaration.container == member.container) {
            // encode the object, which is basically a class, but with metatypeObject
            value memberMap = map {
                keyMetatype -> metatypeObject,
                *encodeClass(typeDeclaration)
            };
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
        else if (is ClassModel member) {
            value memberMap = encodeClass(member);
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
        else if (is InterfaceModel member) {
            value memberMap = encodeInterface(member);
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
        else if (is ValueModel member) {
            value memberMap = encodeValue(member);
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
        else if (is FunctionModel member) {
            value memberMap = encodeFunction(member);
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
        else if (is TypeAliasModel member) {
            value memberMap = encodeTypeAlias(member);
            assert (is String name = memberMap[keyName]);
            m.put(name, memberMap);
        }
    }
    return m;
}

"Encode a class, as seen from within its container (name is not qualified)."
Map<String, Object> encodeClass(ClassModel declaration) {
    // TODO JS model adds a hash to non-toplevel non-shared classes
    //      JS changes "anonymous#" prefix to "anon$"

    value m = HashMap<String, Object>();
    m[keyMetatype] = metatypeClass;
    m[keyName] = declaration.name;

    // alias?
    if (declaration.\ialias) {
        m[keyAlias] = 1;
    }

    // type parameters
    if (nonempty tps = encodeTypeParameters(declaration, {*declaration.typeParameters})) {
        m[keyTypeParams] = tps;
    }

    // self type
    if (exists selfType = declaration.selfType) {
        m[keySelfType] = selfType.declaration.name;
    }

    // extended type
    if (exists extendedType = declaration.extendedType) {
        m[keyExtendedType] = encodeType(extendedType, declaration);
    }

    // satisfied types
    if (nonempty types
            =   if (exists ts = declaration.satisfiedTypes)
                then {*ts}.collect((t) => encodeType(t, declaration))
                else []) {
        m[keySatisfies] = types;
    }

    // case types
    if (nonempty types
            =   if (exists ts = declaration.caseTypes)
                then {*ts}.collect((t) => encodeType(t, declaration))
                else []) {
        m[keyCases] = types;
    }

    // initializer parameters
    if (exists parameterList = declaration.parameterList) {
        m.put(keyParams, encodeValueParameterList(parameterList));
    }

    // annotations
    m.putAll(encodeAnnotations(declaration));

    // members
    m.putAll(encodeMembers({*declaration.members}));

    return m;
}

Map<String, Object> encodeValue(ValueModel v) {
    value m = HashMap<String, Object>();

    m.putAll {
        keyName -> v.name,
        keyMetatype -> (v.transient then metatypeGetter else metatypeAttribute),
        keyType -> encodeType(v.type, v)
    };
    if (v.\idynamic) {
        m.put(keyDynamic, 1);
    }
    m.putAll(encodeAnnotations(v));

    if (exists s = v.setter) {
        value sm = HashMap<String, Object>();
        m.put("$set", sm);
        sm.put(keyMetatype, metatypeSetter);
        sm.putAll(encodeMembers({*s.members}));
        sm.putAll(encodeAnnotations(s));
    }

    m.putAll(encodeMembers({*v.members}));
    return m;
}

Map<String, Object> encodeConstructor(ConstructorModel declaration) {
    value m = HashMap<String, Object>();

    if (exists name = declaration.name) {
        m.put(keyName, name);
    }

    if (declaration.\idynamic) {
        m.put(keyDynamic, 1);
    }

    if (exists list = declaration.parameterList) {
        m.put(keyParams, encodeValueParameterList(list));
    }

    m.putAll(encodeAnnotations(declaration));
    m.putAll(encodeMembers({*declaration.members}));

    return m;
}

Map<String, Object> encodeFunction(FunctionModel declaration) {
    value m = HashMap<String, Object>();

    m.putAll {
        keyName -> declaration.name,
        keyMetatype -> metatypeMethod,
        keyType -> encodeType(declaration.type, declaration)
    };

    if (nonempty tps = encodeTypeParameters(declaration, {*declaration.typeParameters})) {
        m[keyTypeParams] = tps;
    }

    if (declaration.\idynamic) {
        m.put(keyDynamic, 1);
    }

    value flags
        =   0.set(0, declaration.declaredVoid)
            .set(1, declaration.deferred);

    if (!flags.zero) {
        m.put(keyFlags, flags);
    }

    value parameterLists = encodeValueParameterListsFor(declaration);
    if (parameterLists.size > 1 || parameterLists.first nonempty) {
        m.put(keyParams, parameterLists);
    }

    m.putAll(encodeAnnotations(declaration));
    m.putAll(encodeMembers({*declaration.members}));

    return m;
}

{<String -> Object>*} encodeAnnotations(DeclarationModel | PackageModel | ModuleModel d) {
    value paKey => if (d is ModuleModel) then "$mod-pa"
                   else if (d is PackageModel) then "$pkg-pa"
                   else keyPackedAnnotations;

    value packedAnnotations = encodePackedAnnotations(d);

    // TODO non-packed annotations

    return {
        !packedAnnotations.zero then paKey -> packedAnnotations
    }.coalesced;
}

Integer encodePackedAnnotations(DeclarationModel | PackageModel | ModuleModel d) {

    value sealed
        =>  if (is TypeDeclarationModel d, d.sealed) then true else false;

    value final
        =>  if (is TypeDeclarationModel d, d.final) then true else false;

    value late
        =>  if (is ValueModel d, d.late) then true else false;

    value abstract
        =>  if (is ConstructorModel | ClassModel d, d.abstract) then true else false;

    value variable
        =>  if (is ValueModel d, d.variable) then true else false;

    value serializable
        =>  if (is ClassModel d, d.serializable) then true else false;

    value declarationAnnotations
        =>  if (is DeclarationModel d)
            then 0.set(sharedBit, d.shared)
                .set(actualBit, d.actual)
                .set(formalBit, d.formal)
                .set(defaultBit, d.default)
                .set(annotationBit, d.annotation)
                .set(staticBit, d.static)
            else 0;

    return declarationAnnotations
        .set(sealedBit, sealed)
        .set(finalBit, final)
        //.set(nativeBit, d.native) // TODO
        .set(lateBit, late)
        .set(abstractBit, abstract)
        .set(variableBit, variable)
        .set(serializableBit, serializable);
}

Boolean isOrContainsType(DeclarationModel d)
    =>  if (is ValueModel d, d.typeDeclaration.anonymous)
        then true
        else d is TypeDeclarationModel
            || {*d.members}.any(isOrContainsType);

[[Map<String, Object>*]*] encodeValueParameterListsFor(FunctionModel declaration)
    =>  [for (parameterList in declaration.parameterLists)
            encodeValueParameterList(parameterList)];

[Map<String, Object>*] encodeValueParameterList(ParameterListModel list)
    =>  [ for (parameter in list.parameters) encodeValueParameter(parameter) ];

Map<String, Object> encodeValueParameter(ParameterModel parameter) {
    assert (is ValueModel | FunctionModel model = parameter.model);
    return
        if (is ValueModel model)
        then map({
            keyType -> encodeType(model.type, parameter.declaration),
            keyMetatype -> metatypeParameter,
            keyName -> parameter.name,
            (parameter.sequenced) then keySequenced -> 1,
            (parameter.atLeastOne) then "$min1" -> 1
        }.coalesced)
        else map { // is FunctionModel
            "$pt" -> "f",
            keyType -> encodeType(model.type, parameter.declaration),
            keyMetatype -> metatypeParameter,
            keyName -> parameter.name,
            keyParams -> encodeValueParameterListsFor(model)
        };
}

[Map<String, Object>*] encodeTypeParameters(
        DeclarationModel scope,
        {TypeParameterModel*} typeParameters) {

    return typeParameters.collect((tp) {
        value sts
            =   if (exists ts = tp.satisfiedTypes)
                then {*ts}.collect((t) => encodeType(t, scope))
                else [];

        value cts
            =   if (exists ts = tp.caseTypes)
                then {*ts}.collect((t) => encodeType(t, scope))
                else [];

        return map<String, Object> {
            {
                keyName -> tp.name,
                if (tp.covariant)
                    then keyDsVariance -> "out"
                    else null,
                if (tp.contravariant)
                    then keyDsVariance -> "in"
                    else null,
                if (exists selfType = (tp of TypeDeclarationModel).selfType)
                    then keySelfType -> selfType.declaration.name
                    else null,
                if (nonempty sts)
                    then keySatisfies -> sts
                    else null,
                if (nonempty cts)
                    then keyCases -> cts
                    else null,
                if (exists default = tp.defaultTypeArgument)
                    then keyDefault -> encodeType(default, scope)
                    else null
            }.coalesced;
        };
    });
}

Boolean interestingDeclaration(DeclarationModel d) {
    value nativeHeaderWithoutImpl
        =   d.nativeHeader
            && !d.container.getDirectMemberForBackend(
                    d.name, dartBackend.asSet()) exists;

    // encode only the Constructor; create the Functions and Values when parsing
    value functionOrValueForConstructor
        =   ModelUtil.isConstructor(d) && !d is ConstructorModel;

    return !functionOrValueForConstructor
            // use the Value to encode objects, but don't exclude constructors
            // which are also anonymous
            && !(d is ClassModel && d.anonymous)
            && (d.toplevel || d.member || isOrContainsType(d))
            && (isForDartBackend(d) || nativeHeaderWithoutImpl);
}

[<String -> Map<String, Object>>*] encodeMembers(variable {DeclarationModel*} members) {
    // skip native declarations for other backends, unneeded locals, etc.
    members = members.select(interestingDeclaration);

    value classes
        =   members.narrow<ClassModel>().map(encodeClass).collect((m) {
                assert (is String name = m[keyName]);
                return name -> m;
            });

    value interfaces
        =   members.narrow<InterfaceModel>().map(encodeInterface).collect((m) {
                assert (is String name = m[keyName]);
                return name -> m;
            });

    value values
        =   members.narrow<ValueModel>().map(encodeValue).collect((m) {
                assert (is String name = m[keyName]);
                return name -> m;
            });

    value functions
        =   members.narrow<FunctionModel>().map(encodeFunction).collect((m) {
                assert (is String name = m[keyName]);
                return name -> m;
            });

    value constructors
        =   members.narrow<ConstructorModel>()
                    .map(encodeConstructor).collect((m) {
                assert (is String name = m[keyName] else "$def");
                return name -> m;
            });

    value typeAliases
        =   members.narrow<TypeAliasModel>()
                    .map(encodeTypeAlias).collect((m) {
                assert (is String name = m[keyName]);
                return name -> m;
            });

    return {
        if (nonempty classes)
            then keyClasses -> map(classes)
            else null,
        if (nonempty interfaces)
            then keyInterfaces -> map(interfaces)
            else null,
        if (values nonempty || typeAliases nonempty)
            // weird, type aliases are included in keyAttributes!
            then keyAttributes -> map(values.chain(typeAliases))
            else null,
        if (nonempty functions)
            then keyMethods -> map(functions)
            else null,
        if (nonempty constructors)
            then keyConstructors -> map(constructors)
            else null
    }.coalesced.sequence();
}

"Encode an interface, as seen from within its container (name is not qualified)."
Map<String, Object> encodeInterface(InterfaceModel declaration) {
    // TODO JS model adds a hash to non-toplevel non-shared declarations

    value m = HashMap<String, Object>();
    m[keyMetatype] = metatypeInterface;
    m[keyName] = declaration.name;

    // alias?
    if (declaration.\ialias) {
        m[keyAlias] = encodeType(declaration.extendedType, declaration);
    }

    // type parameters
    if (nonempty tps = encodeTypeParameters(declaration, {*declaration.typeParameters})) {
        m[keyTypeParams] = tps;
    }

    // self type
    if (exists selfType = declaration.selfType) {
        m[keySelfType] = selfType.declaration.name;
    }

    // satisfied types
    if (nonempty types
            =   if (exists ts = declaration.satisfiedTypes)
                then {*ts}.collect((t) => encodeType(t, declaration))
                else []) {
        m[keySatisfies] = types;
    }

    // case types
    if (nonempty types
            =   if (exists ts = declaration.caseTypes)
                then {*ts}.collect((t) => encodeType(t, declaration))
                else []) {
        m[keyCases] = types;
    }

    // annotations
    m.putAll(encodeAnnotations(declaration));

    // members
    m.putAll(encodeMembers({*declaration.members}));

    return m;
}

Map<String, Object> encodeTypeAlias(TypeAliasModel declaration) {
    value m = HashMap<String, Object>();
    m[keyMetatype] = metatypeAlias;
    m[keyName] = declaration.name;
    m[keyAlias] = encodeType(declaration.extendedType, declaration);

    // type parameters
    if (nonempty tps = encodeTypeParameters(declaration, {*declaration.typeParameters})) {
        m[keyTypeParams] = tps;
    }

    // annotations
    m.putAll(encodeAnnotations(declaration));

    return m;
}


HashMap<String, Object> encodeType(TypeModel type, DeclarationModel scope) {
    if (ModelUtil.isTypeUnknown(type)) {
        return HashMap<String, Object> { keyName -> typeUnknown };
    }

    if (type.union || type.intersection) {
        value m = HashMap<String, Object>();

        m[keyCompositeType]
            =   if (type.union)
                then typeUnion
                else typeIntersection;

        m[keyTypes]
            =   CeylonIterable {
                    if (type.union)
                    then type.caseTypes
                    else type.satisfiedTypes;
                }.collect((t) => encodeType(t, scope));

        return m;
    }
    //else if (type.tuple && !type.involvesTypeParameters()) {
    //    // TODO
    //    //throw Exception("tuple types not yet supported: ``type``");
    //}

    value m = HashMap<String, Object>();
    value declaration = type.declaration;

    if (declaration.toplevel || type.typeParameter) {
        m.put(keyName, declaration.name);
    }
    else {
        // TODO use qualifiedNameString w/o package part and mangled for locals
        // the 'else ""' is for the "Type" of default constructors
        m.put(keyName, declaration.name else "");
    }

    if (!type.typeParameter) {
        // for non-type parameters, add module and/or package info
        value pkg = declaration.unit.\ipackage else null;
        if (!exists pkg) {
            m.put(keyPackage, ".");
        }
        else if (pkg == scope.unit.\ipackage) {
            m.put(keyPackage, ".");
        }
        else if (pkg.nameAsString == "ceylon.language") {
            m.put(keyPackage, "$");
            m.put(keyModule, "$");
        }
        else {
            m.put(keyPackage, pkg.nameAsString);
            if (pkg.\imodule != scope.unit.\ipackage.\imodule) {
                if (pkg.\imodule.nameAsString == "ceylon.language") {
                    m.put(keyModule, "$");
                }
                else {
                    m.put(keyModule, pkg.\imodule.nameAsString);
                }
            }
        }
    }

    if (exists typeArguments = encodeTypeArguments(type, scope)) {
        m.put(keyTypeArgs, typeArguments);
    }

    return m;
}

Map<String, Map<String, Object>>? encodeTypeArguments
        (TypeModel type, DeclarationModel scope) {

    if (type.typeConstructor) {
        return null;
    }

    value types
        =   loop(type)((TypeModel t)
            =>  t.qualifyingType else finished);

    "Entries from partially qualified type parameter names to type arguments,
     which are maps."
    value entries
        =   types.flatMap((type) {
                value args = type.typeArguments;
                value overrides = type.varianceOverrides else null;
                return CeylonIterable(type.declaration.typeParameters).map((param) {
                    assert (exists arg = args.get(param));
                    value map = encodeType(arg, scope);
                    if (exists override = overrides?.get(param)) {
                        map.put(keyUsVariance, override.ordinal());
                    }
                    // for whatever reason, qualifiedNameString for type parameters
                    // is just the unqualified name. So prepend the qualifiedNameString
                    // of its container.
                    return "``partiallyQualifiedName(param.declaration)``.``param.name``"
                            -> map;
                });
            }).sequence();

    if (entries.empty) {
        return null;
    }
    return map(entries);
}

String partiallyQualifiedName(DeclarationModel d)
    =>  if (exists index = d.qualifiedNameString.firstInclusion("::"))
        then d.qualifiedNameString[index+2...]
        else d.qualifiedNameString;
