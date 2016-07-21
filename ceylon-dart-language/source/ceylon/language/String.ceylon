import ceylon.interop.dart {
    dartString,
    dartInt,
    DartIterable
}
import dart.core {
    DString = String
}

"""A string of characters. Each character in the string is a 
   [[32-bit Unicode character|Character]]. The internal 
   UTF-16 encoding is hidden from clients.
   
   Literal strings may be written between double quotes:
   
       "hello world"
       "\r\n"
       "\{#03C0} \{#2248} 3.14159"
       "\{GREEK SMALL LETTER PI} \{ALMOST EQUAL TO} 3.14159"
   
   Alternatively, a _verbatim string_ may be written between
   tripled double quotes.
   
   The _empty string_, `""`, is a string with no characters.
   
   A string is a [[Category]] of its [[characters]], and of 
   its substrings:
   
       'w' in greeting 
       "hello" in greeting
   
   Strings are [[summable|Summable]]:
   
       String greeting = "hello" + " " + "world";
   
   They are efficiently [[iterable|Iterable]]:
   
       for (char in "hello world") { ... }
   
   They are [[lists|List]] of [[characters|Character]]:
   
       value char = "hello world"[5];
   
   They are [[ranged|Ranged]]:
   
       String who = "hello world"[6...];
   
   Note that since `string[index]` evaluates to the optional 
   type `Character?`, it is often more convenient to write 
   `string[index..index]`, which evaluates to a `String` 
   containing a single character, or to the empty string 
   `""` if `index` refers to a position outside the string.
   
   It is easy to use comprehensions to transform strings:
   
       String { for (s in "hello world") if (s.letter) s.uppercased }
   
   Since a `String` has an underlying UTF-16 encoding, 
   certain operations are expensive, requiring iteration of 
   the characters of the string. In particular, [[size]]
   requires iteration of the whole string, and `get()`,
   `span()`, and `measure()` require iteration from the 
   beginning of the string to the given index."""
by ("Gavin")
tagged("Basic types", "Strings")
shared native final class String(characters)
        extends Object()
        satisfies SearchableList<Character> &
                  Comparable<String> &
                  Summable<String> & 
                  Ranged<Integer,Character,String> {
    
    "The characters that form this string."
    {Character*} characters;
    
    "This string, with all characters in lowercase.
     
     Conversion of uppercase characters to lowercase is
     performed according to a locale-independent mapping
     that produces incorrect results in certain locales
     (e.g. `tr-TR`).
     
     The resulting string may not have the same number of
     characters as this string, since the uppercase 
     representation of certain characters comprises multiple
     characters, for example the lowercase representation of 
     \{LATIN CAPITAL LETTER I WITH DOT ABOVE} is two 
     characters wide."
    shared native String lowercased;
    
    "This string, with all characters in uppercase.
     
     Conversion of lowercase characters to uppercase is
     performed according to a locale-independent mapping
     that produces incorrect results in certain locales
     (e.g. `tr-TR`).
     
     The resulting string may not have the same number of
     characters as this string, since the uppercase 
     representation of certain characters comprises multiple
     characters, for example the uppercase representation of 
     \{LATIN SMALL LETTER SHARP S} is SS."
    shared native String uppercased;
    
    "Split the string into tokens, using the given 
     [[predicate function|splitting]] to determine which 
     characters are separator characters.
     
         value pathElements = path.split('/'.equals);
     
     The flags [[discardSeparators]] and [[groupSeparators]]
     determine how separator characters should occur in the
     resulting stream.
     
     Note that for the case of the empty string, `split()` 
     always produces a stream containing a single empty 
     token. For example:
     
         \"\".split('/'.equals)
     
     evaluates to the nonempty stream `{ \"\" }`."
    shared native {String+} split(
            "A predicate that determines if a character is a
             separator characters at which to split. Default 
             to split at any 
             [[whitespace|Character.whitespace]] character."
            Boolean splitting(Character ch) => ch.whitespace,
            "Specifies that the separator characters
             occurring in the string should be discarded. If 
             `false`, they will be included in the resulting 
             iterator."
            Boolean discardSeparators = true,
            "Specifies that the separator tokens should be 
             grouped eagerly and not be treated as 
             single-character tokens. If `false` each 
             separator token will be of size `1`."
            Boolean groupSeparators = true);
    
    "The first character in the string."
    shared actual native Character? first;
    
    "The last character in the string."
    shared actual native Character? last;
    
    "The rest of the string, without its first character."
    shared actual native String rest;
    
    //"Get the character at the specified index, or `null` if
    // the index falls outside the bounds of this string."
    //shared actual native Character? get(Integer index);
    
    "Get the character at the specified index, where the 
     string is indexed from the _end_ of the string, or 
     `null` if the index falls outside the bounds of this 
     string."
    shared actual native Character? getFromLast(Integer index);
    
    "A sequence containing all indexes of this string."
    shared actual native Integer[] keys => 0:size;
    
    "Join the [[string representations|Object.string]] of 
     the given [[objects]], using this string as a separator."
    shared native String join({Object*} objects) {
        value result = StringBuilder();
        value strings = objects.map(Object.string);
        result.appendAll(empty then strings 
            else strings.interpose(this));
        return result.string;
    }
    
    "Split the string into lines of text, discarding line
     breaks. Recognized line break sequences are `\\n` and 
     `\\r\\n`. The empty string is considered a single line 
     of text."
    see (`value linesWithBreaks`)
    shared native {String+} lines 
            => split('\n'.equals, true, false)
               .spread(String.trimTrailing)('\r'.equals);
    
    "Split the string into lines of text with line breaks.
     Each line will be terminated by a line break sequence,
     `\\n` or `\\r\\n`, except for the very last line. The 
     empty string is considered a single line of text."
    see (`value lines`)
    shared native {String+} linesWithBreaks
            => split('\n'.equals, false, false)
            .partition(2)
            .map(([line, *rest])
                    => if (nonempty rest)
                    then line + rest[0]
                    else line);
    
    "A string containing the characters of this string, 
     after discarding [[whitespace|Character.whitespace]] 
     from the beginning and end of the string."
    shared native String trimmed
            => trim(Character.whitespace);
    
    "A string containing the characters of this string, 
     after discarding the characters matching the given 
     [[predicate function|trimming]] from the beginning and 
     end of the string.
     
         value trimmed = name.trim('_'.equals);
     
     A character is removed from the string if it matches
     the given predicate and if either:
     
     - every character occurring earlier in the string also 
       matches the predicate, or
     - every character occurring later in the string also
       matches the predicate."
    shared actual native String trim(
            "The predicate function that determines whether
             a character should be trimmed"
            Boolean trimming(Character element))
            => if (exists from
                    = firstIndexWhere(not(trimming)),
                   exists to
                    = lastIndexWhere(not(trimming))) 
            then this[from..to]
            else "";
    
    "A string containing the characters of this string, 
     after discarding the characters matching the given 
     [[predicate function|trimming]] from the 
     beginning of the string.
     
     A character is removed from the string if it matches
     the given predicate and every character occurring 
     earlier in the string also matches the predicate."
    shared actual native String trimLeading(
            "The predicate function that determines whether
             a character should be trimmed"
            Boolean trimming(Character element))
            => if (exists from
                    = firstIndexWhere(not(trimming))) 
            then this[from...]
            else "";
    
    "A string containing the characters of this string, 
     after discarding the characters matching the given 
     [[predicate function|trimming]] from the end of the 
     string.
     
     A character is removed from the string if it matches
     the given predicate and every character occurring 
     later in the string also matches the predicate."
    shared actual native String trimTrailing(
            "The predicate function that determines whether
             a character should be trimmed"
            Boolean trimming(Character element))
            => if (exists to
                    = lastIndexWhere(not(trimming))) 
            then this[...to]
            else "";

    "A string containing the characters of this string after 
     collapsing strings of [[whitespace|Character.whitespace]] 
     into single space characters and discarding whitespace 
     from the beginning and end of the string."
    shared native String normalized {
        value result = StringBuilder();
        variable value previousWasWs = false;
        for (ch in this) {
            value currentIsWs = ch.whitespace;
            if (!currentIsWs) {
                result.appendCharacter(ch);
            }
            else if (!previousWasWs) {
                result.appendCharacter(' ');
            }
            previousWasWs = currentIsWs;
        }
        return result.string.trimmed;
    }
    
    "A string containing the characters of this string, with
     the characters in reverse order."
    shared native actual String reversed 
            => StringBuilder()
                .append(this)
                .reverseInPlace()
                .string;
    
    "Determines if this string contains a character at the
     given [[index]], that is, if `0<=index<size`."
    shared native actual Boolean defines(Integer index)
            => 0<=index<size;
    
    "A string containing the characters of this string 
     between the given indexes. If the [[start index|from]] 
     is the same as the [[end index|to]], return a string 
     with a single character. If the start index is larger 
     than the end index, return the characters in the 
     reverse order from the order in which they appear in 
     this string. If both the start index and the end index 
     are larger than the last index in the string, or if 
     both the start index and the end index are smaller than
     the first index in the string, return the empty string. 
     Otherwise, if the last index is larger than the last 
     index in the string, return all characters from the 
     start index to last character of the string.
     
     Using the [[span operator|Ranged.span]], 
     `string.span(to, from)` may be written as 
     `string[from..to]`."
    shared actual native String span(Integer from, Integer to);
    
    "A string containing the characters of this string from 
     the given [[start index|from]] inclusive to the end of 
     the string. If the start index is larger than the last 
     index of the string, return the empty string. If the
     start index is negative, return this string.
     
     Using the [[span operator|Ranged.spanFrom]], 
     `string.spanFrom(from)` may be written as 
     `string[from...]`."
    shared actual native String spanFrom(Integer from)
            => from<size then span(from, size) else "";
    
    "A string containing the characters of this string from 
     the start of the string up to and including the given 
     [[end index|to]]. If the end index is negative, return 
     the empty string. If the end index is larger than the
     last index in this string, return this string.
     
     Using the [[span operator|Ranged.spanTo]], 
     `string.spanTo(to)` may be written as `string[...to]`."
    shared actual native String spanTo(Integer to)
            => to>=0 then span(0, to) else "";
    
    "A string containing the characters of this string 
     beginning at the given [[start index|from]], returning 
     a string no longer than the given [[length]]. If the 
     portion of this string starting at the given index is 
     shorter than the given length, return the portion of 
     this string from the given index until the end of this 
     string. Otherwise, return a string of the given length. 
     If the start index is larger than the last index of the 
     string, return the empty string.
     
     Using the [[measure operator|Ranged.measure]], 
     `string.measure(from, length)` may be written as
     `string[from:length]`."
    shared native actual String measure(Integer from, 
                                        Integer length);
    
    "Select the first characters of this string, returning a 
     string no longer than the given [[length]]. If this 
     string is shorter than the given length, return this 
     string. Otherwise, return a string of the given length."
    shared native actual String initial(Integer length)
            => this[0:length];
    
    "Select the last characters of the string, returning a 
     string no longer than the given [[length]]. If this 
     string is shorter than the given length, return this 
     string. Otherwise, return a string of the given length."
    shared native actual String terminal(Integer length)
            => this[size-length:length];
    
    "Return two strings, the first containing the characters
     that occur before the given [[index]], the second with
     the characters that occur after the given `index`. If 
     the given `index` is outside the range of indices of 
     this string, one of the returned strings will be empty."
    shared native actual String[2] slice(Integer index)
            => [this[...index-1], this[index...]];
    
    "The length of the string (the number of characters it 
     contains). In the case of the empty string, the string 
     has length zero. Note that this operation is 
     potentially costly for long strings, since the
     underlying representation of the characters uses a
     UTF-16 encoding. Use of [[longerThan]] or 
     [[shorterThan]] is highly recommended."
    see (`function longerThan`, `function shorterThan`)
    aliased ("length")
    shared actual native Integer size;
    
    "The index of the last character in the string, or 
     `null` if the string has no characters. Note that this 
     operation is potentially costly for long strings, since 
     the underlying representation of the characters uses a 
     UTF-16 encoding. For any nonempty string:
     
         string.lastIndex == string.size-1"
    shared actual Integer? lastIndex 
            => if (size==0) then null else size-1;
    
    "An iterator for the characters of the string."
    shared actual native Iterator<Character> iterator();
    
    "Returns the character at the given [[index]] in the 
     string, or `null` if the index is before the start of 
     the string or past the end of string. The first 
     character in the string occurs at index zero. The last 
     character in the string occurs at index 
     `string.size-1`.
     
     Using the [[item operator|Correspondence.get]],
     `string.getFromFirst(index)` may be written as
     `string[index]`."
    shared actual native Character? getFromFirst(Integer index);
    
    //shared actual native Boolean->Character? lookup(Integer index);
    
    "Determines if the given object is a `String` and, if 
     so, if it occurs as a substring of this string, or if 
     the object is a `Character` that occurs in this string. 
     That is to say, a string is considered a [[Category]] 
     of its substrings and of its characters.
     
     Using the [[`in` operator|Category.contains]],
     `string.contains(element)` may be written as
     `element in string`."
    shared actual native Boolean contains(Object element)
            => switch (element)
            case (is String) includes(element)
            case (is Character) occurs(element)
            else false;
    
    "Determines if this string begins with the characters of
     the given string or list. Returns `false` if the given
     list contains an element that is not a [[Character]]."
    shared actual native Boolean startsWith(
        "A sequence of [[Character]]s, usually a `String`."
        List<> substring)
            => if (is String substring) 
            then includesAt(0, substring)
            else super.startsWith(substring);
    
    "Determines if this string ends with the characters of
     the given string or list. Returns `false` if the given
     list contains an element that is not a [[Character]]."
    shared actual native Boolean endsWith(
        "A sequence of [[Character]]s, usually a `String`."
        List<> substring)
            => if (is String substring)
            then includesAt(size-substring.size, substring)
            else super.endsWith(substring);
    
    "Returns the concatenation of this string with the
     given string. The resulting string contains the 
     characters of this string followed by the characters of
     the given string.
     
     Using the [[addition operator|Summable.plus]], 
     `string.plus(otherString)` may be written as
     `string + otherString`."
    shared actual native String plus(String other);
    
    "Returns a string formed by repeating this string the 
     given number of [[times]], or the empty string if
     `times<=0`."
    shared actual native String repeat(Integer times) {
        value result = StringBuilder();
        for (_ in 0:times) {
            result.append(this);
        }
        return result.string;
    }
    
    "Returns a string formed by replacing every occurrence 
     in this string of the given nonempty [[substring]] with 
     the given [[replacement]] string, working from the 
     start of this string to the end."
    throws (`class AssertionError`,
            "if the given [[substring]] is empty")
    shared native String replace(String substring, 
                                 String replacement) {
        "string to replace must be nonempty"
        assert (!substring.empty);
        value firstIndex = firstInclusion(substring);
        if (!exists firstIndex) {
            return this;
        }
        value substringLength = substring.size;
        value replacementLength = replacement.size;
        value result = StringBuilder().append(this);
        variable value index = firstIndex;
        while (true) {
            result.replace {
                index = index;
                length = substringLength;
                string = replacement;
            };
            if (exists nextIndex
                = result.firstInclusion(substring, 
                        index + replacementLength)) {
                index = nextIndex;
            }
            else {
                break;
            }
        }
        return result.string;
    }
    
    "Returns a string formed by replacing the first 
     occurrence in this string of the given nonempty 
     [[substring]], if any, with the given [[replacement]] 
     string."
    throws (`class AssertionError`,
            "if the given [[substring]] is empty")
    shared native String replaceFirst(String substring, 
                                      String replacement) {
        "string to replace must be nonempty"
        assert (!substring.empty);
        return 
            if (exists index = firstInclusion(substring)) 
            then initial(index)
                    + replacement
                    + spanFrom(index+substring.size) 
            else this;
    }
    
    "Returns a string formed by replacing the last 
     occurrence in this string of the given nonempty 
     [[substring]], if any, with the given [[replacement]] 
     string."
    throws (`class AssertionError`,
            "if the given [[substring]] is empty")
    shared native String replaceLast(String substring, 
                                     String replacement) {
        "string to replace must be nonempty"
        assert (!substring.empty);
        return 
            if (exists index = lastInclusion(substring)) 
            then initial(index)
                    + replacement
                    + spanFrom(index+substring.size) 
            else this;
    }
    
    "Returns a string formed by removing the given 
     [[prefix]] from the start of this string, if this 
     string [[starts with|startsWith]] the given `prefix`, 
     or this string otherwise."
    shared native String removeInitial(String prefix) 
            => startsWith(prefix) 
            then spanFrom(prefix.size)
            else this;
    
    "Returns a string formed by removing the given 
     [[postfix]] from the end of this string, if this 
     string [[ends with|endsWith]] the given `postfix`, or 
     this string otherwise."
    shared native String removeTerminal(String postfix) 
            => endsWith(postfix) 
            then spanTo(size-postfix.size)
            else this;
    
    function charsEqualIgnoringCase(Character x, Character y) 
            => x==y 
            || x.uppercased==y.uppercased
            || x.lowercased==y.lowercased;
    
    "Compare this string with the given string 
     lexicographically, according to the Unicode code points
     of the characters.
     
     This defines a locale-independent collation that is
     incorrect in some locales.
     
     For more specialized lexicographic comparisons between 
     strings, use [[compareIgnoringCase]] or 
     [[compareCorresponding]]."
    see (`function compareIgnoringCase`,
         `function compareCorresponding`)
    shared actual native Comparison compare(String other)
            => compareCorresponding(this, other, 
                (Character x, Character y) => x<=>y);
    
    "Compare this string with the given string 
     lexicographically, ignoring the case of the characters.
     That is, by considering two characters `x` and `y` as
     equal if:
     
     - `x == y`,
     - `x.uppercased == y.uppercased`, or
     - `x.lowercased == y.lowercased`.
     
     This defines a locale-independent collation that is
     incorrect in some locales.
     
     For more specialized lexicographic comparisons between 
     strings, use [[compareCorresponding]]."
    see (`value Character.lowercased`, 
         `value Character.uppercased`,
         `function compareCorresponding`)
    shared native Comparison compareIgnoringCase(String other)
            => compareCorresponding(this, other, 
                (Character x, Character y) 
                        => charsEqualIgnoringCase(x, y) 
                        then equal 
                        else x.lowercased <=> y.lowercased);
    
    "Determines if this string is longer than the given
     [[length]]. This is a more efficient operation than
     `string.size>length`."
    see (`value size`)
    shared actual native Boolean longerThan(Integer length);
    
    "Determines if this string is shorter than the given
     [[length]]. This is a more efficient operation than
     `string.size>length`."
    see (`value size`)
    shared actual native Boolean shorterThan(Integer length);
    
    "Determines if the given object is a `String`, and if 
     so, if this string has the same [[length|size]], and 
     the same [[characters]], in the same order, as the 
     given [[string|that]].
     
     For more specialized character-wise comparisons between 
     strings, use [[equalsIgnoringCase]] or 
     [[corresponding]]."
    see (`function equalsIgnoringCase`,
         `function corresponding`)
    shared actual native Boolean equals(Object that)
            => if (is String that)
            then corresponding(this, that, 
                    (Character x, Character y) => x==y)
            else false;
    
    "Compare this string with the given string, ignoring the 
     case of the characters. That is, by considering two 
     characters `x` and `y` as equal if:
     
     - `x == y`,
     - `x.uppercased == y.uppercased`, or
     - `x.lowercased == y.lowercased`.
     
     For more specialized character-wise comparisons between 
     strings, use [[corresponding]]."
    see (`value Character.lowercased`, 
         `value Character.uppercased`,
         `function corresponding`)
    shared native Boolean equalsIgnoringCase(String that)
            => corresponding(this, that, 
                charsEqualIgnoringCase);
    
    "A hash code for this `String`, computed from its UTF-16 
     code units."
    shared actual native Integer hash;
    
    "This string."
    shared actual String string => this;
    
    "Determines if this string has no characters, that is, 
     if it has zero [[size]]. This is a _much_ more 
     efficient operation than `string.size==0`."
    see (`value size`)
    shared actual native Boolean empty;
    
    "This string."
    shared actual String coalesced => this;
    
    "This string."
    shared actual String clone() => this;
    
    "Pad this string with the given [[character]], producing 
     a string of the given minimum [[size]], centering the
     string. If this string is not smaller than the given 
     `size`, return this string."
    shared native String pad(Integer size, 
        "The padding character"
        Character character=' ') {
        value length = this.size;
        if (size<=length) {
            return this;
        }
        value left = (size-length)/2;
        value right = left + (size-length)%2;
        value builder = StringBuilder();
        for (_ in 0:left) {
            builder.appendCharacter(character);
        }
        builder.append(this);
        for (_ in 0:right) {
            builder.appendCharacter(character);
        }
        return builder.string;
    }
    
    "Left pad this string with the given [[character]], 
     producing a string of the given minimum [[size]]. If 
     this string is not smaller than the given `size`, 
     return this string."
    shared native String padLeading(Integer size, 
        "The padding character"
        Character character=' ') {
        value length = this.size;
        if (size<=length) {
            return this;
        }
        value builder = StringBuilder();
        for (_ in 0:size-length) {
            builder.appendCharacter(character);
        }
        builder.append(this);
        return builder.string;
    }
    
    "Right pad this string with the given [[character]], 
     producing a string of the given minimum [[size]].  If 
     this string is not smaller than the given `size`, 
     return this string."
    shared native String padTrailing(Integer size, 
        "The padding character"
        Character character=' ') {
        value length = this.size;
        if (size<=length) {
            return this;
        }
        value builder = StringBuilder();
        builder.append(this);
        for (_ in 0:size-length) {
            builder.appendCharacter(character);
        }
        return builder.string;
    }
    
    "Efficiently copy the characters in the segment
     `sourcePosition:length` of this string to the segment 
     `destinationPosition:length` of the given 
     [[character array|destination]].
     
     The given [[sourcePosition]] and [[destinationPosition]] 
     must be non-negative and, together with the given 
     [[length]], must identify meaningful ranges within the 
     two lists, satisfying:
     
     - `size >= sourcePosition+length`, and 
     - `destination.size >= destinationPosition+length`.
     
     If the given `length` is not strictly positive, no
     elements are copied."
    throws (`class AssertionError`, 
        "if the arguments do not identify meaningful ranges 
         within the two lists:
         
         - if the given [[sourcePosition]] or 
           [[destinationPosition]] is negative, 
         - if `size < sourcePosition+length`, or 
         - if `destination.size < destinationPosition+length`.")
    shared native 
    void copyTo(
        "The array into which to copy the elements."
        Array<Character> destination,
        "The index of the first element in this array to 
         copy."
        Integer sourcePosition = 0,
        "The index in the given array into which to copy the 
         first element."
        Integer destinationPosition = 0,
        "The number of elements to copy."
        Integer length 
                = smallest(size - sourcePosition,
                    destination.size - destinationPosition));
    
    "A string containing the characters of this string 
     beginning at the given [[start index|from]], up to, but
     not including, the given [[end index|end]]. If the 
     given end index is greater than the last index of this
     string, return the portion of the string from the given 
     start index until the end of the string. If the start 
     index is larger than the last index of the string, or 
     if the end index is less than one or less than the 
     start index, return the empty string.
     
     For every pair of indexes, `start`, and `end`, and for
     any `string`:
     
         string.substring(start, end) == string[start:end-start]
     
     _Note: this operation is provided to ease migration of
     code written in other languages. It is more idiomatic 
     to use [[measure]] or [[span]] where reasonable._"
    see (`function measure`, `function span`)
    shared native String substring(
        "The inclusive start index"
        Integer from = 0,
        "The exclusive end index" 
        Integer end = size)
            => this[from:end-from];
    
    "The first index greater than or equal to the given 
     [[start index|from]] at which the given substring 
     occurs in this string, if any, or `-1` otherwise.
     
     For any `string` and `substring`, and for every index 
     `from`:
     
         string.indexOf(substring, from) 
            == string.firstInclusion(substring, from) 
                    else -1
         
     _Note: this operation is provided to ease migration of
     code written in other languages. It is more idiomatic 
     to use [[firstInclusion]] where reasonable._"
    see (`function firstInclusion`)
    shared native Integer indexOf(
        "The substring to find within this string"
        String string,
        "The inclusive start index"
        Integer from = 0)
            => firstInclusion(string, from) else -1;
    
    "The last index smaller than or equal to the given 
     [[end index|to]] at which the given substring occurs in 
     this string, if any, or `-1` otherwise.
     
     For any `string` and `substring`, and for every index 
     `from`:
     
         string.lastIndexOf(substring, from) 
            == string.lastInclusion(substring, string.size-from) 
                    else -1
         
     _Note: this operation is provided to ease migration of
     code written in other languages. It is more idiomatic 
     to use [[lastInclusion]] where reasonable._"
    see (`function lastInclusion`)
    shared native Integer lastIndexOf(
        "The substring to find within this string"
        String string,
        "The inclusive start index"
        Integer to = size)
            => lastInclusion(string, size-to) else -1;
    
    "Determines if this string occurs after the given string
     in lexicographic order, returning `false` if the two
     strings are equal."
    shared actual native Boolean largerThan(String other)
            => super.largerThan(other);
    
    "Determines if this string occurs before the given string
     in lexicographic order, returning `false` if the two
     strings are equal."
    shared actual native Boolean smallerThan(String other)
            => super.smallerThan(other);
    
    "Determines if this string occurs after the given string
     in lexicographic order, returning `true` if the two
     strings are equal."
    shared actual native Boolean notSmallerThan(String other)
            => super.notSmallerThan(other);
    
    "Determines if this string occurs before the given string
     in lexicographic order, returning `true` if the two
     strings are equal."
    shared actual native Boolean notLargerThan(String other)
            => super.notLargerThan(other);
    
    shared actual native List<Character> sublistFrom(Integer from);
    shared actual native List<Character> sublistTo(Integer to);
    
    shared actual native {Integer*} indexesWhere(Boolean selecting(Character element));
    shared actual native Integer? firstIndexWhere(Boolean selecting(Character element));
    shared actual native Integer? lastIndexWhere(Boolean selecting(Character element));
    
    shared actual native {Integer*} occurrences(Character element, Integer from, Integer length);
    shared actual native {Integer*} inclusions(List<Character> sublist, Integer from);
    
    shared actual native Boolean occurs(Character element, Integer from, Integer length);
    shared actual native Boolean occursAt(Integer index, Character element);
    shared actual native Boolean includes(List<Character> sublist, Integer from);
    shared actual native Boolean includesAt(Integer index, List<Character> sublist);
        
    shared actual native Integer? firstOccurrence(Character element, Integer from, Integer length);
    shared actual native Integer? lastOccurrence(Character element, Integer from, Integer length);
    shared actual native Integer? firstInclusion(List<Character> sublist, Integer from);
    shared actual native Integer? lastInclusion(List<Character> sublist, Integer from);
        
    shared actual native void each(void step(Character element));
    shared actual native Integer count(Boolean selecting(Character element));
    shared actual native Boolean every(Boolean selecting(Character element));
    shared actual native Boolean any(Boolean selecting(Character element));
    shared actual native Result|Character|Null reduce<Result>
            (Result accumulating(Result|Character partial, Character element));
    shared actual native Character? find(Boolean selecting(Character element));
    shared actual native Character? findLast(Boolean selecting(Character element));
    shared actual native <Integer->Character>? locate(Boolean selecting(Character element));
    shared actual native <Integer->Character>? locateLast(Boolean selecting(Character element));
    shared actual native {<Integer->Character>*} locations(Boolean selecting(Character element));
}

interface BaseStringBoxer<T> {
    shared formal T self;
    shared formal Comparison compare(T other);
}

abstract native("dart")
class BaseString
        extends Object
        satisfies SearchableList<Character>
            & BaseStringBoxer<String>
            // & Comparable<String>
            // & Summable<String>
            // & Ranged<Integer,Character,String>
        {

    String val;

    "This string, boxed. The implementing class will return `this`. The difference between
     this and `string` is that `string` returns an unboxed string (the dart.core.String)."
    shared actual formal
    String self;

    shared
    new ({Character*} characters) extends Object() {
        if (is String characters) {
            val = characters;
        }
        else {
            val = DString.Class.fromCharCodes(DartIterable(
                    characters.map((c) => dartInt(c.integer)))).string;
        }
    }

    shared
    new withString(String s) extends Object() {
        this.val = s;
    }

    shared String lowercased => dartString(self).toLowerCase();
    shared String uppercased => dartString(self).toUpperCase();

    shared
    {String+} split(
            Boolean splitting(Character ch) => ch.whitespace,
            Boolean discardSeparators=true,
            Boolean groupSeparators=true)
            => if (empty) then Singleton(self) else object
            satisfies {String+} {

        // adapted/hacked from Java impl.
        shared actual
        Iterator<String> iterator() => object
                satisfies Iterator<String> {

            // avoid O(n) on substring()
            value seq = self.sequence();
            value it = seq.iterator();
            variable value index = 0;
            variable value first = true;
            variable value lastWasSeparator = false;
            variable value peeked = false;
            variable value peekedWasSeparator = false;
            variable value eof = false;

            Boolean peekSeparator() {
                // idempotent
                if (!peeked) {
                    peeked = true;
                    if (!is Finished next = it.next()) {
                        peekedWasSeparator = splitting(next);
                    }
                    else {
                        eof = true;
                        peekedWasSeparator = false;
                    }
                }
                return peekedWasSeparator;
            }

            void eatChar() {
                peeked = false;
                peekSeparator();
                index++;
            }

            Boolean eatSeparator() {
                value result = peekSeparator();
                if (result) {
                    eatChar();
                }
                return result;
            }

            // calculate eof
            peekSeparator();

            String substring(Integer start, Integer end)
                =>  String(seq[start:end - start]);

            shared actual
            String|Finished next() {
                if (!eof) {
                    variable value start = index;

                    // if we start with a separator, or if we returned a separator
                    // the last time and we are still looking at a separator: return
                    // an empty token once
                    if (((first && start == 0) || lastWasSeparator)
                            && peekSeparator()) {
                        first = false;
                        lastWasSeparator = false;
                        return "";
                    }
                    // are we looking at a separator
                    if (eatSeparator()) {
                        if (groupSeparators) {
                            // eat them all in one go if we group them
                            while (eatSeparator()) {}
                        }
                        // do we return them?
                        if (!discardSeparators) {
                            lastWasSeparator = true;
                            return substring(start, index);
                        }
                        // keep going and eat the next word
                        start = index;
                    }
                    // eat until the next separator
                    while (!eof && !peekSeparator()) {
                        eatChar();
                    }
                    lastWasSeparator = false;
                    return substring(start, index);
                }
                else if (lastWasSeparator) {
                    // we're missing a last empty token before
                    // the EOF because the string ended with a
                    // returned separator
                    lastWasSeparator = false;
                    return "";
                }
                else {
                    return finished;
                }
            }
        };
    };

    shared actual
    Character? first
        =>  !empty then characterFromInteger(dartString(val).runes.first.toInt());

    shared actual
    Character? last
        =>  !empty then characterFromInteger(dartString(val).runes.last);

    shared actual
    String rest
        =>  DString.Class.fromCharCodes(dartString(val).runes.skip(1)).string;

    shared actual
    Character? getFromLast(Integer index)
        =>  if (empty || index < 0)
            then null
            else let (runes = dartString(val).runes) (
                index < runes.length then
                characterFromInteger(runes.elementAt(runes.length - 1 - index).toInt()));

    shared actual
    Integer[] keys => 0:size;

    shared
    String join({Object*} objects)
        =>  DartIterable(objects).join(self);

    shared
    {String*} lines
        =>  split('\n'.equals, true, false).spread(String.trimTrailing)('\r'.equals);

    shared
    {String*} linesWithBreaks
        =>  split('\n'.equals, false, false)
            .partition(2)
            .map((lineWithBreak)
                =>  let (line = lineWithBreak[0], br = lineWithBreak[1])
                    if (exists br) then line+br else line);

    shared
    String trimmed
        =>  trim(Character.whitespace);

    shared actual
    String trim(Boolean trimming(Character element))
        =>  String(super.trim(trimming));

    shared actual
    String trimLeading(Boolean trimming(Character element))
        =>  String(super.trimLeading(trimming));

    shared actual
    String trimTrailing(Boolean trimming(Character element))
        =>  String(super.trimTrailing(trimming));

    shared
    String normalized {
        variable value previousWasWhitespace = false;
        variable value leadingWhitespace = true;
        value sb = StringBuilder();
        for (character in this) {
            if (character.whitespace) {
                if (leadingWhitespace) {
                    continue;
                }
                previousWasWhitespace = true;
            }
            else {
                leadingWhitespace = false;
                if (previousWasWhitespace) {
                    sb.append(" ");
                    previousWasWhitespace = false;
                }
                sb.appendCharacter(character);
            }
        }
        return sb.string;
    }

    shared actual
    String reversed
        =>  DString.Class.fromCharCodes(dartString(val).runes.toList().reversed).string;

    shared actual
    Boolean defines(Integer index)
        =>  0 <= index < size;

    shared actual
    String span(variable Integer from, variable Integer to) {
        value reverse = to < from;
        if (reverse) {
            value tmp = to;
            to = from;
            from = tmp;
        }
        if (to < 0 ) {
            return "";
        }

        value len = size;
        if (len == 0) {
            return self;
        }
        if (from >= len) {
            return "";
        }
        if (to >= len) {
            to = len - 1;
        }
        if (from < 0) {
            from = 0;
        }

        value runes = dartString(val).runes.skip(from).take(to - from + 1);

        if (reverse) {
            return DString.Class.fromCharCodes(runes.toList().reversed).string;
        }
        else {
            return DString.Class.fromCharCodes(runes).string;
        }
    }

    shared actual
    String spanFrom(Integer from)
        =>  span(from, runtime.maxIntegerValue);

    shared actual
    String spanTo(Integer to)
        =>  to >= 0 then span(0, to) else "";

    shared actual
    String measure(Integer from, Integer length)
        =>  length > 0 then span(from, from + length - 1) else "";

    shared actual
    String initial(Integer length)
        =>  length > 0 then span(0, length - 1) else "";

    shared actual
    String terminal(Integer length)
        =>  spanFrom(size-length);

    shared actual
    [String,String] slice(Integer index) {
        if (index < 1) {
            return ["", self];
        }
        value runes = dartString(val).runes;
        return [
            DString.Class.fromCharCodes(runes.take(index)).string,
            DString.Class.fromCharCodes(runes.skip(index)).string
        ];
    }

    shared actual
    Integer size
        =>  dartString(val).runes.length;

    shared actual
    Integer? lastIndex
        =>  !empty then size - 1;

    shared actual
    Iterator<Character> iterator() => object
            satisfies Iterator<Character> {

        value runeIterator = dartString(val).runes.iterator;

        shared actual
        Character|Finished next()
            =>  if (runeIterator.moveNext())
                then characterFromInteger(runeIterator.current)
                else finished;
    };

    shared actual
    Character? getFromFirst(Integer index) {
        if (index < 0) {
            return null;
        }
        value runes = dartString(val).runes;
        if (index < runes.length) {
            return characterFromInteger(runes.elementAt(index).toInt());
        }
        return null;
    }

    shared actual
    Boolean contains(Object element) {
        if (is String element) {
            return dartString(val).contains(dartString(element));
        }
        else if (is Character element) {
            for (c in this) {
                if (c == element) {
                    return true;
                }
            }
        }
        return false;
    }

    shared actual
    Boolean startsWith(List<Anything> substring)
        =>  if (is String substring)
            then dartString(val).startsWith(dartString(substring))
            else everyPair((Character first, Anything second)
                =>  if (is Character second)
                    then first == second
                    else false,
                this, substring);

    shared actual
    Boolean endsWith(List<Anything> substring)
        =>  if (is String substring)
            then dartString(val).endsWith(substring)
            else super.endsWith(substring);

    // needs to be the dart operator '+', so must implement in the real String subclass
    //shared /* actual */ String plus(String other) => val + other;

    shared actual
    String repeat(Integer times)
        =>  dartString(val).times_(times);

    shared
    String replace(String substring, String replacement)
        =>  dartString(val).replaceAll(dartString(substring), replacement);

    shared
    String replaceFirst(String substring, String replacement)
        =>  dartString(val).replaceFirst(dartString(substring), replacement);

    shared
    String replaceLast(String substring, String replacement)
        =>  let (startIndex = dartString(val).lastIndexOf(dartString(substring)))
            if (startIndex == -1)
            then self
            else dartString(val).replaceFirst(
                dartString(substring), replacement, startIndex);

    shared
    String removeInitial(String prefix) 
        =>  if (startsWith(prefix))
            then spanFrom(prefix.size)
            else self;
    
    shared
    String removeTerminal(String postfix) 
        =>  if (endsWith(postfix))
            then spanTo(size-postfix.size)
            else self;

    shared actual
    Comparison compare(String other)
        =>  let (result = dartString(val).compareTo(dartString(other)))
            if (result < 0) then smaller
            else if (result > 0) then larger
            else equal;

    shared
    Comparison compareIgnoringCase(String other)
        =>  uppercased.compare(other.uppercased);

    shared actual
    Boolean longerThan(Integer length)
        =>  getFromFirst(length) exists;

    shared actual
    Boolean shorterThan(Integer length)
        =>  !getFromFirst(length - 1) exists;

    shared actual
    Boolean equals(Object that)
        =>  if (is String that)
            then dartString(val) == dartString(that)
            else false;

    shared
    Boolean equalsIgnoringCase(String that)
        =>  uppercased == that.uppercased;

    shared actual Integer hash => dartString(val).hash;
    shared actual String string => val;
    shared actual Boolean empty => dartString(val).isEmpty;
    shared actual String coalesced => self;
    shared actual String clone() => self;

    shared
    String pad(Integer size, Character character=' ') {
        value length = this.size;
        if (size <= length) {
            return self;
        }
        value leftPad = (size - length) / 2;
        value rightPad = size - leftPad - length;
        value sb = StringBuilder();
        for (_ in 0:leftPad) {
            sb.appendCharacter(character);
        }
        sb.append(self);
        for (_ in 0:rightPad) {
            sb.appendCharacter(character);
        }
        return sb.string;
    }

    shared
    String padLeading(Integer size, Character character=' ') {
        value length = this.size;
        if (size <= length) {
            return val;
        }
        value padAmount = size - length;
        return character.string.repeat(padAmount) + val;
    }

    shared
    String padTrailing(Integer size, Character character=' ') {
        value length = this.size;
        if (size <= length) {
            return val;
        }
        value padAmount = size - length;
        return val + character.string.repeat(padAmount);
    }

    shared
    void copyTo(
            Array<Character> destination,
            Integer sourcePosition = 0,
            Integer destinationPosition = 0,
            Integer length
                =   smallest(size - sourcePosition,
                        destination.size - destinationPosition)) {

        // FIXME test all of this. Is it correct to throw?

        variable value i = destinationPosition;
        for (c in skip(sourcePosition - 1).take(length)) {
            destination.set(i++, c);
        }
        if (i < destinationPosition + length) {
            throw Exception("Expected to copy ``length`` items but only copied \
                             ``i - destinationPosition`` items");
        }
    }
    
    shared
    String substring(Integer from = 0, Integer end = size)
        =>  self[from:end-from];

    shared
    Integer indexOf(String string, Integer from = 0)
        =>  firstInclusion(string, from) else -1;
    
    shared
    Integer lastIndexOf(String string, Integer to = size)
        =>  lastInclusion(string, size-to) else -1;

    shared actual
    {Integer*} indexesWhere(Boolean selecting(Character element))
        =>  { for (index->element in this.indexed)
                if (exists element, selecting(element))
                  index };

    //shared actual native List<Character> sublistFrom(Integer from);
    //shared actual native List<Character> sublistTo(Integer to);

    //shared actual native Integer? firstIndexWhere(Boolean selecting(Character element));
    //shared actual native Integer? lastIndexWhere(Boolean selecting(Character element));

    //shared actual native {Integer*} occurrences(Character element, Integer from, Integer length);
    //shared actual native {Integer*} inclusions(List<Character> sublist, Integer from);

    //shared actual native Boolean occurs(Character element, Integer from, Integer length);
    //shared actual native Boolean occursAt(Integer index, Character element);
    //shared actual native Boolean includes(List<Character> sublist, Integer from);
    //shared actual native Boolean includesAt(Integer index, List<Character> sublist);

    //shared actual native Integer? firstOccurrence(Character element, Integer from, Integer length);
    //shared actual native Integer? lastOccurrence(Character element, Integer from, Integer length);
    //shared actual native Integer? firstInclusion(List<Character> sublist, Integer from);
    //shared actual native Integer? lastInclusion(List<Character> sublist, Integer from);

    // needs to be dart operators, so must implement in the real String subclass
    //shared /* actual */ native Boolean largerThan(String other);
    //shared /* actual */ native Boolean smallerThan(String other);
    //shared /* actual */ native Boolean notSmallerThan(String other);
    //shared /* actual */ native Boolean notLargerThan(String other);

    //shared actual native void each(void step(Character element));
    //shared actual native Integer count(Boolean selecting(Character element));
    //shared actual native Boolean every(Boolean selecting(Character element));
    //shared actual native Boolean any(Boolean selecting(Character element));
    //shared actual native Result|Character|Null reduce<Result>
    //        (Result accumulating(Result|Character partial, Character element));
    //shared actual native Character? find(Boolean selecting(Character element));
    //shared actual native Character? findLast(Boolean selecting(Character element));
    //shared actual native <Integer->Character>? locate(Boolean selecting(Character element));
    //shared actual native <Integer->Character>? locateLast(Boolean selecting(Character element));
    //shared actual native {<Integer->Character>*} locations(Boolean selecting(Character element));
}
