import ceylon.ast.redhat {
    compilationUnitToCeylon
}
import ceylon.collection {
    LinkedList
}
import ceylon.interop.java {
    createJavaByteArray,
    CeylonIterable
}
import ceylon.io.charset {
    utf8
}

import com.redhat.ceylon.compiler.typechecker {
    TypeCheckerBuilder
}
import com.redhat.ceylon.compiler.typechecker.io {
    VirtualFile
}
import com.vasileff.ceylon.dart.ast {
    DartImportDirective,
    DartSimpleIdentifier,
    DartCompilationUnit,
    DartSimpleStringLiteral
}
import com.vasileff.jl4c.guava.collect {
    javaList
}

import java.io {
    InputStream,
    ByteArrayInputStream
}
import java.util {
    List
}
import com.vasileff.ceylon.dart.compiler {
    CompilationContext,
    augmentNode,
    dartBackend,
    debugVisitor,
    computeCaptures,
    computeClassCaptures,
    CompilerBug,
    hasError
}

shared
[DartCompilationUnit*] compile(Boolean verbose=false, {String*} listings = {}) {

    // TODO this function is becoming a mess

    // make sure Dart backend is registered
    noop(dartBackend);

    value virtualFiles = listings.indexed.map((listing) => object
            satisfies VirtualFile {
        shared actual
        List<out VirtualFile> children
            =>  javaList {};

        shared actual
        Integer compareTo(VirtualFile other)
            =>  switch (path.compare(other.path))
                case (smaller) -1
                case (larger) 1
                case (equal) 0;

        shared actual
        Boolean folder
            =>  false;

        shared actual
        InputStream inputStream
            =>  ByteArrayInputStream(
                    createJavaByteArray(
                        utf8.encode(listing.item)));

        shared actual
        String name
            =>  "virtual-``listing.key``.ceylon";

        shared actual
        String path
            =>  name;

        shared actual
        Boolean \iexists()
            =>  true;
    });

    value builder = TypeCheckerBuilder();
    virtualFiles.each((vf) => builder.addSrcDirectory(vf));

    value typeChecker = builder.typeChecker;
    typeChecker.process();

    // print typechecker messages
    if (verbose) {
        CeylonIterable(typeChecker.messages).each(
                compose(process.writeErrorLine, Object.string));
    }

    value phasedUnits = CeylonIterable(
            typeChecker.phasedUnits.phasedUnits);

    value dartCompilationUnits = LinkedList<DartCompilationUnit>();

    for (phasedUnit in phasedUnits) {
        if (verbose) {
            print("========================");
            print("== TC-AST");
            print("========================");
            print(phasedUnit.compilationUnit);
        }
        value unit = compilationUnitToCeylon(
                phasedUnit.compilationUnit,
                augmentNode);
        if (verbose) {
            print("========================");
            print("== AST");
            print("========================");
            print(unit);
            print("========================");
            print("== DART");
            print("========================");
        }

        if (hasError(unit)) {
            process.writeError("Typechecker errors exist; skipping Dart backend");
        }
        else {
            try {
                value ctx = CompilationContext(phasedUnit);

                unit.visit(debugVisitor);
                computeCaptures(unit, ctx);
                computeClassCaptures(unit, ctx);

                ctx.topLevelVisitor.transformCompilationUnit(unit);

                value dartCompilationUnit =
                    DartCompilationUnit {
                        // TODO process all module.ceylon imports
                        [DartImportDirective {
                            DartSimpleStringLiteral(
                                "dart:core");
                            DartSimpleIdentifier(
                                "$dart$core");
                        },
                        DartImportDirective {
                            DartSimpleStringLiteral(
                                "package:ceylon/language/language.dart");
                            DartSimpleIdentifier(
                                "$ceylon$language");
                        }];
                        ctx.compilationUnitMembers.sequence();
                    };

                dartCompilationUnits.add(dartCompilationUnit);
            } catch (CompilerBug b) {
                process.writeError("Compiler bug:\n" + b.message);
            }
        }
    }
    return dartCompilationUnits.sequence();
}