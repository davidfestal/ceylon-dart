package com.vasileff.ceylon.dart.compiler.loader;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import com.redhat.ceylon.common.Backend;
import com.redhat.ceylon.common.Backends;
import com.redhat.ceylon.model.typechecker.model.Annotation;
import com.redhat.ceylon.model.typechecker.model.Module;
import com.redhat.ceylon.model.typechecker.model.ModuleImport;
import com.redhat.ceylon.model.typechecker.model.Package;

public class JsonModule extends Module {

    private Map<String,Object> model;
    private boolean loaded = false;

    private Backend dartBackend = Backend.registerBackend("Dart", "dart");

    private boolean dartNative = false;

    /**
     * Is this module a native Dart library?
     */
    public boolean isDartNative() {
        return dartNative;
    }

    @SuppressWarnings("unchecked")
    public void setModel(Map<String, Object> value) {
        if (model != null) {
            final String modName = (String)model.get("$mod-name");
            final String modVers = (String)model.get("$mod-version");
            if (!(Objects.equals(modName, value.get("$mod-name"))
                    && Objects.equals(modVers, value.get("$mod-version")))) {
                throw new IllegalStateException("JsonModule " + modName+"/"+modVers
                        + " receives new module " + value.get("$mod-name")+"/"+value.get("$mod-version"));
            }
            return;
        }
        model = value;
        final String binVersion = (String)model.get("$mod-bin");
        final int dotidx = binVersion.indexOf('.');
        setJsMajor(Integer.parseInt((String)binVersion.substring(0,dotidx), 10));
        setJsMinor(Integer.parseInt((String)binVersion.substring(dotidx+1), 10));
        if (model.get("$mod-pa") != null) {
            int bits = (int)model.get("$mod-pa");
            setNativeBackends(JsonPackage.hasAnnotationBit(bits, "native") ? dartBackend.asSet() : Backends.ANY);
        }
        Map<String,Object> moduleAnns = (Map<String,Object>)model.get("$mod-anns");
        if (moduleAnns != null) {
            for (Map.Entry<String, Object> e : moduleAnns.entrySet()) {
                String name = e.getKey();
                Annotation ann = new Annotation();
                ann.setName(name);
                for (String arg : (List<String>)e.getValue()) {
                    ann.addPositionalArgument(arg);
                }
                getAnnotations().add(ann);
            }
        }
        if (model.get(MetamodelGenerator.KEY_NATIVE_DART) != null) {
            dartNative = (boolean)model.get(MetamodelGenerator.KEY_NATIVE_DART);
        }
    }
    public Map<String, Object> getModel() {
        return model;
    }

    void loadDeclarations() {
        if (loaded)return;
        if (model != null) {
            if (!loaded) {
                loaded=true;
                for (Map.Entry<String, Object> e : model.entrySet()) {
                    if (!e.getKey().startsWith("$mod-")) {
                        JsonPackage p = new JsonPackage(e.getKey());
                        p.setModule(this);
                        getPackages().add(p);
                    }
                }
            }
        }
    }

    @SuppressWarnings("unchecked")
    public Map<String,Object> getModelForPackage(String name) {
        return model == null ? null : (Map<String,Object>)model.get(name);
    }

    @Override
    public Package getPackage(String name) {
        if ("default".equals(name)) {
            name = "";
        }
        // search direct packages
        Package p = getDirectPackage(name);
        if (p != null) {
            return p;
        }

        // search imported modules
        HashSet<Module> visited = new HashSet<Module>();
        visited.add(this);
        for (ModuleImport imp : getImports()) {
            p = getPackageFromImport(name, imp.getModule(), visited);
            if (p != null) {
                return p;
            }
        }

        // not found
        return null;
    }

    private Package getPackageFromImport(String name, Module module, Set<Module> visited) {
        // break circularities
        if (!visited.add(module)) {
            return null;
        }

        // search direct packages
        Package p = module.getDirectPackage(name);
        if (p != null) {
            return p;
        }

        // search exports
        for (ModuleImport imp : module.getImports()) {
            if (imp.isExport()) {
                p = getPackageFromImport(name, imp.getModule(), visited);
                if (p != null) {
                    return p;
                }
            }
        }

        // not found
        return null;
    }

    public List<ModuleImport> getImports() {
        final List<ModuleImport> s = super.getImports();
        ArrayList<ModuleImport> r = new ArrayList<>(s.size());
        r.addAll(s);
        return r;
    }

}
