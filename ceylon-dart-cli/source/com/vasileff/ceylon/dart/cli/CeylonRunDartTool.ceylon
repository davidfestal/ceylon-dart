import ceylon.collection {
    HashMap,
    MutableSet,
    HashSet
}
import ceylon.file {
    parsePath,
    Path,
    Directory,
    File
}
import ceylon.interop.java {
    createJavaObjectArray,
    createJavaStringArray,
    javaString,
    CeylonIterable
}
import ceylon.process {
    createProcess,
    currentOutput,
    currentError,
    currentInput
}

import com.redhat.ceylon.cmr.api {
    ArtifactContext,
    ModuleQuery,
    RepositoryManager
}
import com.redhat.ceylon.cmr.ceylon {
    RepoUsingTool
}
import com.redhat.ceylon.common {
    ModuleUtil
}
import com.redhat.ceylon.common.tool {
    argument=argument__SETTER,
    ToolError
}
import com.redhat.ceylon.common.tools {
    CeylonTool
}
import com.vasileff.ceylon.dart.compiler {
    ReportableException,
    parseJsonModel
}

import java.lang {
    ObjectArray,
    JString=String
}
import java.nio.file {
    JFiles=Files,
    JPath=Path,
    FileAlreadyExistsException
}
import java.util {
    ListResourceBundle,
    JMap=Map,
    JList=List
}

shared
class CeylonRunDartTool() extends RepoUsingTool(resourceBundle) {

    shared variable
    argument {
        argumentName="module";
        multiplicity="1";
        order=1;
    }
    String moduleString = "";

    shared actual
    void initialize(CeylonTool? ceylonTool) {
        // noop
    }

    shared actual
    suppressWarnings("expressionTypeNothing")
    void run() {
        try {
            value exitCode = doRun();
            process.exit(exitCode);
        }
        catch (ReportableException e) {
            throw object extends ToolError(e.message, e.cause) {};
        }
    }

    function moduleFile(String moduleName, String? moduleVersion) {
        if (exists file = ceylonFile(repositoryManager.getArtifact(ArtifactContext(
                        moduleName, moduleVersion, ArtifactContext.\iDART)))) {
            return file;
        }
        throw ReportableException("Cannot find module: \
                 ``ModuleUtil.makeModuleName(moduleName, moduleVersion)``");
    }

    function moduleModelFile(String moduleName, String? moduleVersion) {
        if (exists file = ceylonFile(repositoryManager.getArtifact(ArtifactContext(
                        moduleName, moduleVersion, ArtifactContext.\iDART_MODEL)))) {
            return file;
        }
        throw ReportableException("Cannot find model metadata for module: \
                 ``ModuleUtil.makeModuleName(moduleName, moduleVersion)``");
    }

    function moduleModel(String moduleName, String? moduleVersion) {
        value modelFile = moduleModelFile(moduleName, moduleVersion);

        value parsedJson = parseJsonModel(modelFile);

        if (!exists parsedJson) {
            throw ReportableException(
                    "Unable to parse json model metadata for module: \
                     ``ModuleUtil.makeModuleName(moduleName, moduleVersion)``");
        }
        return parsedJson;
    }

    function dependencyNamesFromJson(JMap<JString,Object> model) {
        assert (is JList<out Anything>? dependencies
            =   model.get(javaString("$mod-deps")));

        "We'll always have dependencies; at least the language module."
        assert (exists dependencies);

        return
        CeylonIterable(dependencies).collect((dependency) {
            assert (is JString | JMap<out Anything, out Anything> dependency);

            switch (dependency)
            case (is JMap<out Anything, out Anything>) {
                assert (is JString path = dependency.get(javaString("path")));
                return path.string;
            }
            case (is JString) {
                return dependency.string;
            }
        });
    }

    // TODO check versions for conflicts (including non-shared)
    MutableSet<[String,String]> gatherDependencies(
            String moduleName,
            String moduleVersion,
            MutableSet<[String,String]> dependencies
                =   HashSet<[String, String]>()) {

        value pair = [moduleName, moduleVersion];
        value alreadyThere = !dependencies.add(pair);

        if (alreadyThere) {
            return dependencies;
        }

        value parsedJson = moduleModel(moduleName, moduleVersion);

        dependencyNamesFromJson(parsedJson).each((dep)
            =>  gatherDependencies {
                    ModuleUtil.moduleName(dep);
                    ModuleUtil.moduleVersion(dep) else "";
                    dependencies;
                });

        return dependencies;
    }

    Integer doRun() {
        value dartPath = findDartInPath(process.environmentVariableValue("PATH"));
        if (!exists dartPath) {
            throw ReportableException("Cannot find dart executable in path.");
        }

        // Make sure the language module has been installed
        // Although, the program may actually import some other version...
        verifyLanguageModuleAvailability(repositoryManager);

        // TODO support default modules
        if (ModuleUtil.isDefaultModule(moduleString)) {
            throw ReportableException(
                    "Default modules not yet supported: ``moduleString``");
        }

        value moduleName
            =   ModuleUtil.moduleName(moduleString);

        value moduleVersion
            =   checkModuleVersionsOrShowSuggestions(
                    repositoryManager,
                    moduleName,
                    ModuleUtil.moduleVersion(moduleString),
                    ModuleQuery.Type.\iDART,
                    null, null) else "";

        value dependencies
            =   gatherDependencies(moduleName, moduleVersion);

        value dependencyFiles
            =   dependencies.map((pair)
                =>  let ([name, version] = pair)
                    name -> moduleFile(name, version));

        value [packageRootPath, moduleMap]
            =   createTemporaryPackageRoot(dependencyFiles);

        assert (exists programModuleSymlink
            =   moduleMap[moduleName]?.string);

        value p
            =   createProcess {
                    command = dartPath.name;
                    arguments = [
                        "--package-root=" + packageRootPath.string,
                        programModuleSymlink];
                    path = dartPath.directory.path;
                    input = currentInput;
                    output = currentOutput;
                    error = currentError;
                };

        p.waitForExit();
        return p.exitCode else 0;
    }
}

[JPath, Map<String, JPath>] createTemporaryPackageRoot({<String->File>*} modules) {
    value moduleToLinkMap = HashMap<String, JPath>();

    // create temporary Dart package root directory
    value packageRootPath = JFiles.createTempDirectory("ceylon-run-dart");
    packageRootPath.toFile().deleteOnExit();

    // populate with modules
    for (name->file in modules) {
        variable JPath symLinkPath = packageRootPath;

        value nameParts = name.split('.'.equals);
        for (part in nameParts) {
            symLinkPath = symLinkPath.resolve(part);
            try {
                // this throws if "recreating" common dirs, like /com, since packages
                // may share leading path segments.
                JFiles.createDirectory(symLinkPath);
                symLinkPath.toFile().deleteOnExit();
            } catch (FileAlreadyExistsException e) {}
        }
        symLinkPath = symLinkPath.resolve(nameParts.last + ".dart");
        JFiles.createSymbolicLink(symLinkPath, javaPath(file));
        symLinkPath.toFile().deleteOnExit();
        moduleToLinkMap.put(name, symLinkPath);
    }
    return [packageRootPath, moduleToLinkMap];
}

File? findDartInPath(String? path) {
    assert (exists sep = operatingSystem.pathSeparator.first);

    // TODO handle Links, support windows (dart.exe?)
    return path?.split(sep.equals)
            ?.map(parsePath)
            ?.map(Path.resource)
            ?.narrow<Directory>()
            ?.flatMap((d) => d.files("dart"))
            ?.filter(File.executable)
            ?.first;
}

object resourceBundle extends ListResourceBundle() {
    shared actual ObjectArray<ObjectArray<Object>> contents
        =>  createJavaObjectArray([
                ["module.not.found", "Module {0} not found in the following repositories:"],
                ["missing.version.suggestion", "Not all repositories could be searched for matching modules/versions, try again using a specific version"],
                ["version.not.found", "Version {0} not found for module {1}"],
                ["missing.version", "Missing required version number for module {0}"],
                ["try.versions", "Try one of the following versions: "],
                ["compiling", "Source found for module {0}, compiling..."],
                ["compilation.failed", "Failed to compile sources"]
            ].map((e) => createJavaStringArray(e)));
}

void verifyLanguageModuleAvailability(RepositoryManager repositoryManager) {
    value version = `module`.version;

    value languageModuleFile = repositoryManager.getArtifact(
        ArtifactContext("ceylon.language", version, ArtifactContext.\iDART))
        else null;

    if (!exists languageModuleFile) {
        throw ReportableException(
              "The Ceylon/Dart language module version ``version`` was not found.
               Try installing with:

                   ceylon install-dart --out ~/.ceylon/repo");
    }
}
