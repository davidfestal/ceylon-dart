"A declaration that can have type parameters."
native shared sealed interface GenericDeclaration {
    
    "The list of type parameters declared on this generic declaration."
    shared formal TypeParameter[] typeParameterDeclarations;
    
    "Finds a type parameter by name. Returns `null` if not found."
    shared formal TypeParameter? getTypeParameterDeclaration(String name);
}
