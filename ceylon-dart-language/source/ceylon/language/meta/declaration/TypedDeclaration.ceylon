"Declaration which has an open type."
native shared sealed interface TypedDeclaration {
    
    "The open type for this declaration. For example, the open type for `List<T> f<T>()` is `List<T>`."
    shared formal OpenType openType;
}
