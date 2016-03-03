import ceylon.interop.java {
    javaClass,
    JavaIterable,
    javaString,
    CeylonList,
    CeylonIterable
}

import com.redhat.ceylon.cmr.ceylon {
    OutputRepoUsingTool
}
import com.redhat.ceylon.common.config {
    DefaultToolOptions
}
import com.redhat.ceylon.common.tool {
    AnnotatedToolModel,
    ToolFactory,
    argument=argument__SETTER,
    option=option__SETTER,
    description=description__SETTER,
    optionArgument=optionArgument__SETTER,
    ToolError
}
import com.redhat.ceylon.common.tools {
    CeylonTool,
    SourceArgumentsResolver,
    CeylonToolLoader
}
import com.vasileff.ceylon.dart.compiler {
    dartBackend,
    compileDart,
    CompilationStatus,
    ReportableException,
    Warning
}
import com.vasileff.jl4c.guava.collect {
    javaList
}

import java.lang {
    JString=String
}
import java.util {
    JList=List,
    EnumSet
}

shared
class CeylonCompileDartTool() extends OutputRepoUsingTool(null) {

    shared variable
    argument {
        argumentName = "moduleOrFile";
        multiplicity = "*";
    }
    JList<JString> moduleOrFile = javaList<JString>{javaString("*")};

    shared variable option
    description("Wrap typeChecker.process() in TypeCache.doWithoutCaching \
                 (default is false)")
    Boolean doWithoutCaching = false;

    shared variable option
    description("Generate a source artificat. Warning: this can cause problems if the
                 generated '.src' file conflicts with an existing '.src' artifact
                 generated by another backend, potentially in a different repository.")
    Boolean generateSourceArtifact = false;

    shared variable
    option { shortName = 'W'; }
    optionArgument { argumentName = "warnings"; }
    description {
        "Suppress the reporting of the given warnings. \
         If no `warnings` are given then suppresss the reporting of all warnings, \
         otherwise just suppresss those which are present. \
         Allowed flags include: \
         `filenameNonAscii`, `filenameCaselessCollision`,
         `deprecation`, `compilerAnnotation`,
         `doclink`, `expressionTypeNothing`,
         `unusedDeclaration`, `unusedImport`,
         `ceylonNamespace`, `javaNamespace`,
         `suppressedAlready`, `suppressesNothing`,
         `unknownWarning`, `ambiguousAnnotation`,
         `similarModule`, `importsOtherJdk`,
         `javaAnnotationElement`, `syntaxDeprecation`,
         `unsoundTypeTest`.";
    }
    EnumSet<Warning> suppressWarning = EnumSet.noneOf(javaClass<Warning>());

    shared actual variable
    option { shortName = 'd'; }
    optionArgument { argumentName = "flags"; }
    description {
        "Produce verbose output. \
         If no `flags` are given then be verbose about everything, \
         otherwise just be verbose about the flags which are present. \
         Allowed flags include: `all`, `loader`, `ast`, `rhAst`, \
         `code`, `profile`, `files`.";
    }
    String? verbose = null;

    shared variable option
    description {
        "Suppress output of successfull actions. \
         Errors and warnings will still be logged.";
    }
    Boolean quiet = false;

    shared variable optionArgument
    description("Repeat compilation the specified number of times (useful for
                 performance testing).")
    JString? repeat = null;

    shared variable option
    description {
        "Include 'count nodes' visitors to determine baseline performance.";
    }
    Boolean baselinePerfTest = false;

    function verboseOption(String key)
        =>  if (exists v = verbose)
            then v.empty || v.contains("all") || v.contains(key)
            else false;

    Boolean verboseProfile => verboseOption("profile");
    Boolean verboseAst => verboseOption("ast");
    Boolean verboseRhAst => verboseOption("rhAst");
    Boolean verboseCode => verboseOption("code");
    Boolean verboseFiles => verboseOption("files");

    shared actual
    void initialize(CeylonTool? ceylonTool) {}

    suppressWarnings("expressionTypeNothing")
    shared actual
    void run() {
        try {
            value result = doRun();
            switch (result)
            case (CompilationStatus.success) { }
            case (CompilationStatus.errorTypeChecker
                    | CompilationStatus.errorDartBackend) {
                process.exit(1);
            }
        }
        catch (ReportableException e) {
            throw object extends ToolError(e.message, e.cause) {};
        }
    }

    CompilationStatus doRun() {
        checkCeylonVersion();
        verifyLanguageModuleAvailability(repositoryManager);

        value sourceDirectories = applyCwd(DefaultToolOptions.compilerSourceDirs);
        value resources = DefaultToolOptions.compilerResourceDirs;
        value resolver = SourceArgumentsResolver(
                sourceDirectories, resources, ".ceylon", ".dart");

        resolver.cwd(cwd).expandAndParse(moduleOrFile, dartBackend);

        if (resolver.sourceFiles.empty && resolver.sourceModules.empty) {
            throw ReportableException("No modules or source files to compile.");
        }

        function doCompileDart()
            =>  compileDart {
                    sourceDirectories = CeylonList(sourceDirectories);
                    sourceFiles = CeylonList(resolver.sourceFiles);
                    moduleFilters = CeylonIterable(resolver.sourceModules)
                            .collect(Object.string);
                    repositoryManager = repositoryManager;
                    outputRepositoryManager = outputRepositoryManager;
                    suppressWarning = CeylonIterable(suppressWarning);
                    generateSourceArtifact = generateSourceArtifact;
                    doWithoutCaching = doWithoutCaching;
                    verboseAst = verboseAst;
                    verboseRhAst = verboseRhAst;
                    verboseCode = verboseCode;
                    verboseProfile = verboseProfile;
                    verboseFiles = verboseFiles;
                    quiet = quiet;
                    baselinePerfTest = baselinePerfTest;
                }[1];

        for (_ in 0:(parseInteger(repeat?.string else "0") else 0)) {
            doCompileDart();
        }
        return doCompileDart();
    }
}

"Run the CeylonCompileDartTool, using arguments from [[process.arguments]]."
shared
void runCompileDartTool() {
    value args = JavaIterable(process.arguments.map(javaString));
    value tool = CeylonCompileDartTool();
    value toolLoader = CeylonToolLoader();
    value toolFactory = ToolFactory();
    value toolModel = AnnotatedToolModel<CeylonCompileDartTool>("compile-dart");
    toolModel.toolLoader = toolLoader;
    toolModel.toolClass = javaClass<CeylonCompileDartTool>();
    toolFactory.bindArguments(toolModel, tool, CeylonTool(), args);
    tool.run();
}
