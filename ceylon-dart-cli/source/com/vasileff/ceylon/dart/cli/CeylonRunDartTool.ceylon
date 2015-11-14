import ceylon.collection {
    HashMap
}
import ceylon.file {
    parsePath,
    Path,
    Directory,
    File,
    lines
}
import ceylon.interop.java {
    createJavaObjectArray,
    createJavaStringArray
}
import ceylon.json {
    JsonObject=Object,
    parse
}
import ceylon.process {
    createProcess,
    currentOutput,
    currentError,
    currentInput
}

import com.redhat.ceylon.cmr.api {
    ArtifactContext,
    ModuleQuery
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

import java.io {
    JFile=File
}
import java.lang {
    ObjectArray
}
import java.nio.file {
    JFiles=Files,
    JPath=Path,
    FileAlreadyExistsException
}
import java.util {
    ListResourceBundle
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
        value dartPath = findDartInPath(process.environmentVariableValue("PATH"));
        if (!exists dartPath) {
            process.writeErrorLine("Error: cannot find dart executable in path.");
        }
        assert (exists dartPath);

        // TODO handle default modules
        suppressWarnings("unusedDeclaration")
        value moduleIsDefault = ModuleUtil.isDefaultModule(moduleString);
        String moduleName = ModuleUtil.moduleName(moduleString);
        String? moduleVersion = checkModuleVersionsOrShowSuggestions(
                repositoryManager,
                moduleName,
                ModuleUtil.moduleVersion(moduleString),
                ModuleQuery.Type.\iDART,
                null, null);

        // collect required artifacts, generate temporary dart package root
        value programModuleFile
            =   repositoryManager.getArtifact(ArtifactContext(
                        moduleName, moduleVersion, ArtifactContext.\iDART));

        value programModuleModelFile
            =   assertedCeylonFile(repositoryManager.getArtifact(ArtifactContext(
                        moduleName, moduleVersion, ArtifactContext.\iDART_MODEL)));

        // There *has* to be a better way to parse a file!
        value parsedJson = parse("".join(lines(programModuleModelFile)));

        // TODO better error reporting
        "Invalid json found in model file"
        assert(is JsonObject parsedJson);

        value namesAndVersions
            =   parsedJson.getArray("$mod-deps").strings.map((dep)
                =>  dep.split('/'.equals));

        // TODO transitive dependencies, better error handling
        value importedModules
            =   namesAndVersions.map((pair) {
                    if (exists name = pair.getFromFirst(0),
                        exists version = pair.getFromFirst(1)) {
                        return name ->
                            repositoryManager.getArtifact(ArtifactContext(
                                    name, version, ArtifactContext.\iDART));
                    }
                    else {
                        return null;
                    }
                }).coalesced;

        // use *our* version as the language module version!
        value version = `module`.version;

        value languageModuleFile = repositoryManager.getArtifact(
            ArtifactContext("ceylon.language", version, ArtifactContext.\iDART))
            else null;

        if (!exists languageModuleFile) {
            print("The Ceylon/Dart language module version ``version`` was not found.
                   Try installing with:

                       ceylon install-dart --out ~/.ceylon/repo");
            process.exit(1);
            return;
        }

        // TODO use *our* version, or the one specified by the module?
        value [packageRootPath, moduleMap] = createTemporaryPackageRoot(
            [moduleName -> programModuleFile,
                *importedModules]);
             //"ceylon.language" -> languageModuleFile]);

        assert (exists programModuleSymlink = moduleMap[moduleName]?.string);

        value p = createProcess {
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
        process.exit(p.exitCode else 0);
    }
}

[JPath, Map<String, JPath>] createTemporaryPackageRoot({<String->JFile>*} modules) {
    value moduleToLinkMap = HashMap<String, JPath>();

    // create temporary Dart package root directory
    value packageRootPath = JFiles.createTempDirectory("ceylon-run-dart");
    packageRootPath.toFile().deleteOnExit();

    // populate with modules
    for (name->jFile in modules) {
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
        JFiles.createSymbolicLink(symLinkPath, jFile.toPath());
        symLinkPath.toFile().deleteOnExit();
        moduleToLinkMap.put(name, symLinkPath);
    }
    return [packageRootPath, moduleToLinkMap];
}

File? findDartInPath(String? path) {
    // TODO don't assume single character separator, I guess.
    assert (exists sep = operatingSystem.pathSeparator.first);

    // TODO handle Links
    // TODO windows name (dart.exe?)
    return path?.split(sep.equals)
            ?.map(parsePath)
            ?.map(Path.resource)
            ?.narrow<Directory>()
            ?.flatMap((d) => d.files("dart"))
            ?.filter(File.executable)
            ?.first;
}

shared
class CeylonRunDartToolError(String message) extends ToolError(message) {}

// TODO use resource file
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
