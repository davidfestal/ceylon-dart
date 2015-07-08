import ceylon.ast.core {
    ValueDefinition,
    Specifier,
    CompilationUnit,
    ValueDeclaration
}

import com.redhat.ceylon.model.typechecker.model {
    PackageModel=Package
}

class MiscTransformer(CompilationContext ctx)
        extends BaseTransformer<Anything>(ctx) {

    shared actual
    DartVariableDeclarationList transformValueDeclaration
            (ValueDeclaration that) {

        value info = ValueDeclarationInfo(that);

        value packagePrefix =
                if (info.declarationModel.container is PackageModel)
                then "$package$"
                else "";

        return
        DartVariableDeclarationList {
            null;
            ctx.dartTypes.dartTypeName(
                    info.declarationModel,
                    info.declarationModel.type);
            [DartVariableDeclaration {
                DartSimpleIdentifier {
                    packagePrefix + ctx.dartTypes.getName(info.declarationModel);
                };
                initializer = null;
            }];
        };
    }

    shared actual
    DartVariableDeclarationList transformValueDefinition
            (ValueDefinition that) {

        if (!that.definition is Specifier) {
            throw CompilerBug(that, "LazySpecifier not supported");
        }

        value info = ValueDefinitionInfo(that);

        value packagePrefix =
                if (info.declarationModel.container is PackageModel)
                then "$package$"
                else "";

        return
        DartVariableDeclarationList {
            null;
            ctx.dartTypes.dartTypeName(
                    info.declarationModel,
                    info.declarationModel.type);
            [DartVariableDeclaration {
                DartSimpleIdentifier {
                    packagePrefix + ctx.dartTypes.getName(info.declarationModel);
                };
                ctx.withLhsType(info.declarationModel.type, ()
                    =>  that.definition.expression.transform(expressionTransformer));
            }];
        };
    }

    "Transforms the declarations of the [[CompilationUnit]]. **Note:**
     imports are ignored."
    shared actual
    [DartCompilationUnitMember*] transformCompilationUnit(CompilationUnit that)
        =>  that.declarations.flatMap((d)
            => d.transform(topLevelTransformer)).sequence();
}