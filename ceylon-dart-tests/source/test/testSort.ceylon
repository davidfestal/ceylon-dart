@test
shared void testSort() {
    // disabled: see https://github.com/ceylon/ceylon-compiler/issues/953
    //check(!sort {} nonempty, "sort()");
    //check(!sort([]) nonempty, "sort()");
    //check(!sort({}) nonempty, "sort({})");
    check(sort {3, 2, 1} == {1, 2, 3}.sequence(), "Sort integers");
    check(sort {3.3, 2.2, 1.1} == {1.1, 2.2, 3.3}.sequence(), "Sort floats");
    check(sort {'c', 'b', 'a'} == {'a', 'b', 'c'}.sequence(), "Sort characters");
    check(sort {"c", "b", "a"} == {"a", "b", "c"}.sequence(), "Sort strings");
    check(sort {StubComparable(3), StubComparable(2), StubComparable(1)} == {StubComparable(1), StubComparable(2), StubComparable(3)}.sequence(), "Sort custom comparable");
}

class StubComparable(Integer n) satisfies Comparable<StubComparable> {
    shared actual Comparison compare(StubComparable other) {
        return n<=>other.n;
    }
    shared actual Boolean equals(Object other) {
        if (is StubComparable other) {
            return n==other.n;
        }
        else {
            return false;
        }
    }
}
