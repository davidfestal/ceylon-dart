import ceylon.ast.core {
    FunctionDefinition,
    Block,
    InvocationStatement,
    ValueDefinition,
    Return,
    FunctionShortcutDefinition,
    Assertion,
    IsCondition,
    ValueSpecification,
    ValueDeclaration,
    IfElse,
    ForFail,
    VariablePattern,
    PrefixPostfixStatement,
    AssignmentStatement,
    While,
    Condition
}
import ceylon.language.meta {
    type
}

import com.redhat.ceylon.model.typechecker.model {
    FunctionOrValueModel=FunctionOrValue
}

import org.antlr.runtime {
    Token
}

class StatementTransformer(CompilationContext ctx)
        extends BaseTransformer<[DartStatement*]>(ctx) {

    shared actual [DartStatement] transformAssignmentStatement(AssignmentStatement that)
        =>  [DartExpressionStatement {
                withLhsNoType(() => that.expression.transform(expressionTransformer));
            }];

    "Parents must set `returnTypeTop`"
    see(`function generateFunctionExpression`)
    shared actual
    [DartReturnStatement] transformReturn(Return that)
        =>  if (exists result = that.result) then
                [DartReturnStatement {
                    withLhs {
                        null;
                        ctx.assertedReturnDeclaration;
                        () => result.transform(expressionTransformer);
                    };
                }]
            else
                [DartReturnStatement()];

    shared actual
    [DartIfStatement] transformIfElse(IfElse that) {
        // workaround https://github.com/ceylon/ceylon-compiler/issues/2219
        value elseStatement =
                    (switch (c = that.elseClause?.child)
                    case (is Block) transformBlock(c).first
                    case (is IfElse) transformIfElse(c).first
                    case (is Null) null);

        return [DartIfStatement {
            generateBooleanDartCondition(that.ifClause.conditions);
            statementTransformer.transformBlock(that.ifClause.block).first;
            elseStatement;
        }];
    }

    shared actual
    [DartWhileStatement] transformWhile(While that)
        =>  [DartWhileStatement {
                generateBooleanDartCondition(that.conditions);
                statementTransformer.transformBlock(that.block).first;
            }];

    shared actual
    [DartStatement] transformInvocationStatement(InvocationStatement that)
        =>  [DartExpressionStatement(withLhsNoType(()
            =>  expressionTransformer.transformInvocation(that.expression)))];

    shared actual
    [DartVariableDeclarationStatement] transformValueDefinition(ValueDefinition that)
        =>  [DartVariableDeclarationStatement(miscTransformer
                .transformValueDefinition(that))];

    shared actual
    [DartStatement] transformValueSpecification(ValueSpecification that)
        =>  [DartExpressionStatement {
                withLhsNoType {
                    () => generateAssignmentExpression {
                        that;
                        ValueSpecificationInfo(that).declaration;
                        () => that.specifier.expression.transform(expressionTransformer);
                    };
                };
            }];

    shared actual
    DartStatement[] transformPrefixPostfixStatement(PrefixPostfixStatement that)
        =>  [DartExpressionStatement {
                withLhsNoType(() => that.expression.transform(expressionTransformer));
            }];

    shared actual
    DartStatement[] transformForFail(ForFail that) {
        value pattern = that.forClause.iterator.pattern;
        if (that.failClause exists) {
            throw CompilerBug(that, "FailClause not yet supported");
        }
        if (!pattern is VariablePattern) {
            throw CompilerBug(that,
                "For pattern type not yet supported: " + type(pattern).string);
        }
        assert (is VariablePattern pattern);

        value variableInfo = UnspecifiedVariableInfo(pattern.variable);

        value variableDeclaration = variableInfo.declarationModel;

        // Don't erase to native for the loop variable; avoid premature unboxing
        ctx.disableErasureToNative.add(variableDeclaration);

        // The iterator
        value dartIteratorVariable = DartSimpleIdentifier {
            ctx.dartTypes.createTempNameCustom("iterator");
        };

        // Temp variable for result of `next()`
        value dartLoopVariable = DartSimpleIdentifier {
            ctx.dartTypes.createTempNameCustom("element");
        };

        // Discover the type of the iterator and obtain a function that
        // will create an expression that yields the iterator
        value [iteratorType, _, iteratorGenerator]
            =   generateInvocationGenerator {
                    that;
                    ExpressionInfo(that.forClause.iterator.iterated);
                    "iterator";
                    [];
                };

        // Simplify iteratorType to a denotable supertype in case it
        // is a union, intersection, or other non-denotable
        // Note: we don't have to do this; we could just use `iteratorType`.
        // But 1) we can, and 2) on occasion it removes a cast from the while
        // loop expession, which of course doesn't matter.
        value iteratorDenotableType = ctx.ceylonTypes.denotableType {
            iteratorType;
            ctx.ceylonTypes.iteratorDeclaration;
        };

        // Discover the type of the loop variable and obtain a function that
        // will create an expression that calls `next` on the iterator
        value [loopVariableType, __, nextInvocationGenerator]
            =   generateInvocationGeneratorSynthetic {
                    that;
                    iteratorDenotableType;
                    // NonNative since that's how we created
                    // `iteratorDenotable` (`withLhsNonNative`)
                    () => withBoxingNonNative {
                        that;
                        iteratorDenotableType;
                        dartIteratorVariable;
                    };
                    "next";
                    [];
                };

        return
        [DartBlock {
            // Declare the loop variable
            [DartVariableDeclarationStatement {
                DartVariableDeclarationList {
                    null;
                    ctx.dartTypes.dartTypeName {
                        that;
                        loopVariableType;
                        false; false;
                    };
                    [DartVariableDeclaration {
                        dartLoopVariable;
                        null;
                    }];
                };
            },
            // Declare and create the iterator
            DartVariableDeclarationStatement {
                DartVariableDeclarationList {
                    null;
                    ctx.dartTypes.dartTypeName {
                        that;
                        iteratorDenotableType;
                        eraseToNative = false;
                        eraseToObject = false;
                    };
                    [DartVariableDeclaration {
                        dartIteratorVariable;
                        withLhsNonNative {
                            iteratorDenotableType;
                            iteratorGenerator;
                        };
                    }];
                };
            },
            DartWhileStatement {
                // Invoke next() and test for Finished
                DartIsExpression {
                    DartAssignmentExpression {
                        dartLoopVariable;
                        DartAssignmentOperator.equal;
                        withLhs {
                            loopVariableType;
                            null;
                            nextInvocationGenerator;
                        };
                    };
                    ctx.dartTypes.dartTypeName {
                        that;
                        ctx.ceylonTypes.finishedType;
                        false; false;
                    };
                    true;
                };
                // The forClause block
                DartBlock {
                    // Define the "real" loop variable
                    [DartVariableDeclarationStatement {
                        DartVariableDeclarationList {
                            null;
                            ctx.dartTypes.dartTypeNameForDeclaration {
                                that;
                                variableDeclaration;
                            };
                            [DartVariableDeclaration {
                                DartSimpleIdentifier {
                                    ctx.dartTypes.getName(variableDeclaration);
                                };
                                withLhs {
                                    variableInfo.declarationModel.type;
                                    variableDeclaration;
                                    () => withBoxing {
                                        that;
                                        loopVariableType;
                                        null;
                                        dartLoopVariable;
                                    };
                                };
                            }];
                        };
                    },
                    // Statements
                    *expand(that.forClause.block.transformChildren(
                            statementTransformer))];
                };
            }];
        }];
    }

    shared actual
    [DartFunctionDeclarationStatement] transformFunctionDefinition
            (FunctionDefinition that)
        =>  [DartFunctionDeclarationStatement(
            generateFunctionDefinition(that))];

    shared actual
    [DartFunctionDeclarationStatement] transformFunctionShortcutDefinition
            (FunctionShortcutDefinition that)
        =>  [DartFunctionDeclarationStatement(
            generateFunctionDefinition(that))];

    shared actual
    [DartBlock] transformBlock(Block that)
        // Dart block's only have Statements. Declarations are wrapped:
        //      FunctionDeclarationStatement(FunctionDeclaration)
        //      VariableDeclarationStatement(VariableDeclarationList)
        //
        // TODO classes and interfaces need jump back to toplevel w/captures
        =>  [DartBlock([*expand(that.transformChildren(this))])];

    shared actual
    [DartStatement*] transformValueDeclaration(ValueDeclaration that) {
        value info = ValueDeclarationInfo(that);
        if (info.declarationModel.parameter) {
            // ignore; must be a declaration for
            // a parameter reference
            return [];
        }
        return super.transformValueDeclaration(that);
    }

    shared actual
    [DartStatement*] transformAssertion(Assertion that) {
        // children are 'Annotations' and 'Conditions'
        // 'Conditions' has 'Condition's.

        // TODO Annotations
        // TODO Don't visit conditions individually?
        // annotations, especially 'doc', need to apply to
        // each condition. Any other annotations matter?

        // won't be empty
        return [*that.conditions.conditions.flatMap(generateConditionAssertion)];
    }

    [DartStatement+] generateConditionAssertion(Condition that) {
        "Only IsConditions supported"
        assert (is IsCondition that);

        return generateIsConditionAssertion(that);
    }

    [DartStatement+] generateIsConditionAssertion(IsCondition that) {
        value info = IsConditionInfo(that);

        "The Ceylon source code for the condition"
        value errorMessage =
                ctx.tokens[info.token.tokenIndex..
                           info.endToken.tokenIndex]
                .map(Token.text)
                .reduce(plus) else "";

        value [replacementDeclaration,
                tempDefinition,
                conditionExpression,
                replacementDefinition] = generateIsCheck(that);

        variable [DartStatement?*] statements = [
            replacementDeclaration,
            tempDefinition,
            // if (x is !y) then throw new AssertionError(...)
            DartIfStatement {
                conditionExpression;
                DartExpressionStatement {
                    DartThrowExpression {
                        DartInstanceCreationExpression {
                            const = false;
                            DartConstructorName {
                                DartTypeName {
                                    DartPrefixedIdentifier {
                                        DartSimpleIdentifier("$ceylon$language");
                                        DartSimpleIdentifier(ctx.dartTypes.getName(
                                            ctx.ceylonTypes.assertionErrorDeclaration));
                                    };
                                };
                            };
                            DartArgumentList {
                                [DartSimpleStringLiteral {
                                    "Violated: ``errorMessage``";
                                }];
                            };
                        };
                    };
                };
            },
            replacementDefinition
        ];

        if (tempDefinition exists) {
            // scope the temp variable in a block
            statements = [
                replacementDeclaration,
                DartBlock(statements[1:3].coalesced.sequence())];
        }

        assert (nonempty result = statements.coalesced.sequence());
        return result;
    }

    shared
    [DartStatement?, DartStatement?, DartExpression, DartStatement?]
    generateIsCheck(IsCondition that) {

        // IsCondition holds a TypedVariable that may
        // or may not include a specifier to define a new variable

        // NOTE: There is no ast node for the typechecker's
        // Tree.IsCondition.Variable (we just get the specifier
        // and identifier from that node, but not the model info).
        // Instead, use ConditionInfo.variableDeclarationModel.

        // TODO don't hardcode AssertionError
        // TODO string escaping
        // TODO types! (including union and intersection, but not reified yet)
        // TODO check not null for Objects
        // TODO check null for Null
        // TODO consider null issues for negated checks
        // TODO consider erased types, like `Integer? i = 1; assert (is Integer i);`

        //value typeInfo = TypeInfo(that.variable.type);
        value info = IsConditionInfo(that);

        //"The type we are testing for"
        //value isType = typeInfo.typeModel;

        "The declaration model for the new variable"
        value variableDeclaration = info.variableDeclarationModel;

        //"The type of the new variable (intersection of isType and expression/old type)"
        //value variableType = variableDeclaration.type;

        "The expression node if defining a new variable"
        value expression = that.variable.specifier?.expression;

        DartStatement? replacementDeclaration;
        DartStatement? tempDefinition;
        DartExpression conditionExpression;
        DartStatement? replacementDefinition;

        // new variable, or narrowing existing?
        if (exists expression) {
            // 1. declare the new variable
            // 2. evaluate expression to temp variable of type of expression
            // 3. check type of the temp variable
            // 4. set the new variable, with appropriate boxing
            // (perform 2-4 in a new block to scope the temp var)

            value variableIdentifier = DartSimpleIdentifier(
                    ctx.dartTypes.getName(variableDeclaration));

            value expressionType = ExpressionInfo(expression).typeModel;

            value tempIdentifier = DartSimpleIdentifier(
                    ctx.dartTypes.createTempName(variableDeclaration));

            // 1. declare the new variable
            replacementDeclaration =
            DartVariableDeclarationStatement {
                DartVariableDeclarationList {
                    keyword = null;
                    ctx.dartTypes.dartTypeNameForDeclaration {
                        that;
                        variableDeclaration;
                    };
                    [DartVariableDeclaration {
                        variableIdentifier;
                    }];
                };
            };

            // 2. evaluate to tmp variable
            tempDefinition =
            DartVariableDeclarationStatement {
                DartVariableDeclarationList {
                    keyword = null;
                    ctx.dartTypes.dartTypeName(that, expressionType, true);
                    [DartVariableDeclaration {
                        tempIdentifier;
                        // possibly erase to a native type!
                        withLhsNative {
                            expressionType;
                            () => expression.transform(expressionTransformer);
                        };
                    }];
                };
            };

            // 3. perform is check on tmp variable
            conditionExpression = generateIsExpression(tempIdentifier, that.negated);

            // 4. set replacement variable
            replacementDefinition =
            DartExpressionStatement {
                DartAssignmentExpression {
                    variableIdentifier;
                    DartAssignmentOperator.equal;
                    withLhs {
                        null;
                        variableDeclaration;
                        () => withBoxing {
                            that;
                            // as noted above, tmpVariable may be erased. Maybe
                            // when narrowing optionals like String?.
                            expressionType;
                            null;
                            tempIdentifier;
                        };
                    };
                };
            };
        }
        else {
            tempDefinition = null;
            replacementDeclaration = null;

            // check type of the original variable,
            // possibly declare new variable with a narrowed type
            assert(is FunctionOrValueModel originalDeclaration =
                    variableDeclaration.originalDeclaration);

            value originalIdentifier = DartSimpleIdentifier(
                    ctx.dartTypes.getName(originalDeclaration));

            conditionExpression = generateIsExpression(originalIdentifier, that.negated);

            // erasure to native may have changed
            // erasure to object may have changed
            // type may have narrowed
            value dartTypeChanged =
                ctx.dartTypes.dartTypeModelForDeclaration(originalDeclaration) !=
                ctx.dartTypes.dartTypeModelForDeclaration(variableDeclaration);

            replacementDefinition =
                if (!dartTypeChanged)
                then null
                else
                    DartVariableDeclarationStatement {
                        DartVariableDeclarationList {
                            keyword = null;
                            ctx.dartTypes.dartTypeNameForDeclaration {
                                that;
                                variableDeclaration;
                            };
                            [DartVariableDeclaration {
                                DartSimpleIdentifier {
                                    ctx.dartTypes.createReplacementName{
                                        variableDeclaration;
                                    };
                                };
                                withLhs {
                                    null;
                                    variableDeclaration;
                                    () => withBoxing {
                                        that;
                                        originalDeclaration.type; // good enough???
                                        // FIXME possibly false assumption that refined
                                        // will be null for non-initial declarations
                                        // (is refinedDeclaration propagated?)
                                        originalDeclaration;
                                        DartSimpleIdentifier {
                                            ctx.dartTypes.getName(originalDeclaration);
                                        };
                                    };
                                };
                            }];
                        };
                    };
        }

        return [replacementDeclaration,
                tempDefinition,
                conditionExpression,
                replacementDefinition];
    }

    DartExpression generateIsExpression(
            DartExpression expressionToCheck,
            Boolean not) {

        return
        DartIsExpression {
            expressionToCheck;
            // TODO actual type!
            ctx.dartTypes.dartObject;
            notOperator = !not;
        };
    }

    suppressWarnings("unusedDeclaration")
    DartStatement? singleStatementOrNull([DartStatement*] statements) {
        if (nonempty statements) {
            if (statements.size > 1) {
                return DartBlock(statements);
            }
            else {
                return statements.first;
            }
        }
        return null;
    }
}
