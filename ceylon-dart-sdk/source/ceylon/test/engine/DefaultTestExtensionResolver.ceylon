import ceylon.language.meta.declaration {
    ClassDeclaration,
    InterfaceDeclaration
}
import ceylon.test.engine.spi {
    TestExtension,
    TestExtensionResolver
}
import ceylon.collection {
    HashMap,
    HashSet
}
import ceylon.test {
    TestDescription
}
import ceylon.test.annotation {
    TestExtensionAnnotation
}
import ceylon.language.meta {
    typeLiteral
}
import ceylon.language.meta.model {
    Interface
}

"Default implementation of [[TestExtensionResolver]]."
shared class DefaultTestExtensionResolver() satisfies TestExtensionResolver {
    
    value extensionCache = HashMap<ClassDeclaration,TestExtension>();
    value testExtensionInterface = `interface TestExtension`;
    
    shared actual {TestExtensionType*} resolveExtensions<TestExtensionType>(TestDescription description) given TestExtensionType satisfies TestExtension {
        assert(is Interface<TestExtension> interfaceModel = typeLiteral<TestExtensionType>());
        return resolveExtensionClasses(description).
                filter(isType(interfaceModel.declaration)).
                map(resolveExtensionInstance).
                narrow<TestExtensionType>();
    }
    
    {ClassDeclaration*} resolveExtensionClasses(TestDescription description) {
        value extensionClasses = HashSet<ClassDeclaration>();
        if( exists f = description.functionDeclaration ) {
            f.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
            if( f.toplevel ) {
                f.containingPackage.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
                f.containingModule.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
            }
        } 
        else if( exists c = description.classDeclaration ) {
            variable ClassDeclaration? var = c;
            while(exists supertype = var) {
                supertype.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
                var = supertype.extendedType?.declaration;                
            }
            c.containingPackage.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
            c.containingModule.annotations<TestExtensionAnnotation>().each((e) => extensionClasses.addAll(e.extensions));
        }
        
        return extensionClasses;
    }
    
    TestExtension resolveExtensionInstance(ClassDeclaration extensionClass) {
        if (extensionCache.keys.contains(extensionClass)) {
            assert (exists extension = extensionCache.get(extensionClass));
            return extension;
        }
        else {
            if( extensionClass.anonymous ) {
                assert(is TestExtension extension = extensionClass.objectValue?.get());
                extensionCache[extensionClass] = extension;
                return extension;
            }
            else {
                assert (is TestExtension extension = extensionClass.instantiate());
                extensionCache[extensionClass] = extension;
                return extension;
            }
        }
    }
    
    Boolean isType(InterfaceDeclaration requestedType)(ClassDeclaration extensionClass) {
        // WORKAROUND #5830 API for checking if type satisfy/extends another type
        // https://github.com/ceylon/ceylon/issues/5830
        
        if( requestedType == testExtensionInterface) {
            return true;
        }
        
        variable ClassDeclaration? var = extensionClass;
        while(exists supertype = var) {
            for( satisfiedType in supertype.satisfiedTypes ) {
                if( satisfiedType.declaration == requestedType ) {
                    return true;
                }
            }
            var = supertype.extendedType?.declaration;
        }
        
        return false;
    }
    
}