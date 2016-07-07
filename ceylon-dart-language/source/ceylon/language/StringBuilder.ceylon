import java.lang {
    JStringBuilder=StringBuilder,
    JCharacter=Character {
        toChars,
        charCount
    },
    IndexOutOfBoundsException
}
import dart.core {
    DStringBuffer = StringBuffer,
    DStringBufferClass = StringBuffer_C
}

"""Builder utility for constructing [[strings|String]] by 
   incrementally appending strings or characters.
   
       value builder = StringBuilder();
       builder.append("hello");
       builder.appendCharacter(' ');
       builder.append("world");
       String hello = builder.string; //hello world"""
tagged("Strings")
shared native final class StringBuilder() 
        satisfies SearchableList<Character> { 
    
    "The number characters in the current content, that is, 
     the [[size|String.size]] of the produced [[string]]."
    shared actual native Integer size;
    
    shared actual native Integer? lastIndex;
    
    "The resulting string. If no characters have been
     appended, the empty string."
    shared actual native variable String string;
    
    shared actual native Iterator<Character> iterator();
    
    "Returns a string of the given [[length]] containing
     the characters beginning at the given [[index]]."
    deprecated ("use [[measure]]")
    shared native
    String substring(Integer index, Integer length)
            => measure(index, length);
    
    shared actual native
    Character? getFromFirst(Integer index);
    
    "Append the characters in the given [[string]]."
    shared native 
    StringBuilder append(String string);
    
    "Append the characters in the given [[strings]]."
    shared native 
    StringBuilder appendAll({String*} strings) {
        for (s in strings) {
            append(s);
        }
        return this;
    }
    
    "Prepend the characters in the given [[string]]."
    shared native 
    StringBuilder prepend(String string);
    
    "Prepend the characters in the given [[strings]]."
    shared native 
    StringBuilder prependAll({String*} strings) {
        for (s in strings) {
            prepend(s);
        }
        return this;
    }
    
    "Append the given [[character]]."
    shared native 
    StringBuilder appendCharacter(Character character);
    
    "Prepend the given [[character]]."
    shared native 
    StringBuilder prependCharacter(Character character);
    
    "Append a newline character."
    shared native 
    StringBuilder appendNewline() => appendCharacter('\n');
    
    "Append a space character."
    shared native 
    StringBuilder appendSpace() => appendCharacter(' ');
    
    "Remove all content and return to initial state."
    shared native 
    StringBuilder clear();
    
    "Insert a [[string]] at the specified [[index]]."
    shared native 
    StringBuilder insert(Integer index, String string);
    
    "Insert a [[character]] at the specified [[index]]."
    shared native 
    StringBuilder insertCharacter
            (Integer index, Character character);
    
    "Replaces the specified [[number of characters|length]] 
     from the current content, starting at the specified 
     [[index]], with the given [[string]]. If [[length]] is 
     nonpositive, nothing is replaced, and the `string` is
     simply inserted at the specified `index`."
    shared native 
    StringBuilder replace
            (Integer index, Integer length, String string);
    
    "Deletes the specified [[number of characters|length]] 
     from the current content, starting at the specified 
     [[index]]. If [[length]] is nonpositive, nothing is 
     deleted."
    shared native 
    StringBuilder delete(Integer index, Integer length/*=1*/);
    
    "Deletes the specified [[number of characters|length]] 
     from the start of the string. If `length` is 
     nonpositive, nothing is deleted."
    shared native 
    StringBuilder deleteInitial(Integer length);
    
    "Deletes the specified [[number of characters|length]] 
     from the end of the string. If `length` is nonpositive, 
     nothing is deleted."
    shared native 
    StringBuilder deleteTerminal(Integer length);
    
    "Reverses the order of the current characters."
    shared native 
    StringBuilder reverseInPlace();
    
    "The first index at which the given 
     [[list of characters|sublist]] occurs as a sublist, 
     that is greater than or equal to the optional 
     [[starting index|from]]."
    shared actual native
    Integer? firstInclusion(List<Character> sublist,
        Integer from);
    
    "The last index at which the given 
     [[list of characters|sublist]] occurs as a sublist, 
     that falls within the range `0:size-from+1-sublist.size` 
     defined by the optional [[starting index|from]], 
     interpreted as a reverse index counting from the _end_
     of the list."
    shared actual native
    Integer? lastInclusion(List<Character> sublist,
        Integer from);
    
    "The first index at which the given [[character]] occurs, 
     that is greater than or equal to the optional 
     [[starting index|from]]."
    shared actual native
    Integer? firstOccurrence(Character character,
        Integer from, Integer length);
    
    "The last index at which the given [[character]] occurs, 
     that falls within the range `0:size-from` defined by 
     the optional [[starting index|from]], interpreted as a 
     reverse index counting from the _end_ of the list."
    shared actual native
    Integer? lastOccurrence(Character character,
        Integer from, Integer length);
    
    shared actual native
    {Integer*} inclusions(List<Character> sublist, 
        Integer from);
    
    shared actual native
    {Integer*} occurrences(Character character, 
        Integer from, Integer length);
    
    shared actual 
    Boolean occursAt(Integer index, Character character) 
            => if (exists ch = getFromFirst(index))
                then ch == character else false;
    
    shared actual 
    Boolean includesAt(Integer index, List<Character> sublist)
            => this[index:sublist.size] == sublist;
    
    shared actual native 
    String measure(Integer from, Integer length);
    
    shared actual 
    String initial(Integer length) 
            => measure(0, length);
    
    shared actual 
    String terminal(Integer length) 
            => measure(size-length, length);
    
    shared actual native String span(Integer from, Integer to);
    shared actual native String spanTo(Integer to);
    shared actual native String spanFrom(Integer from);
    
    shared actual native Boolean equals(Object that);
    shared actual native Integer hash;
}

shared native("jvm") final class StringBuilder() 
        satisfies SearchableList<Character> {
    
    value builder = JStringBuilder();
    
    shared actual native("jvm") Integer size 
            => builder.codePointCount(0, builder.length());
    
    shared actual native("jvm") Integer? lastIndex 
            => if (builder.length() == 0)
            then null
            else builder.length() - 1;
    
    shared actual native("jvm") String string 
            => builder.string;
    
    native("jvm") assign string 
            => builder.replace(0, builder.length(), string);
    
    shared actual native("jvm") 
    Iterator<Character> iterator() {
        object stringBuilderIterator
                satisfies Iterator<Character> {
            variable Integer offset = 0;
            shared actual Character|Finished next() {
                if (offset < builder.length()) {
                    Integer codePoint = 
                            builder.codePointAt(offset);
                    offset += charCount(codePoint);
                    return codePoint.character;
                }
                else {
                    return finished;
                }
            }
        }
        return stringBuilderIterator;
    }
    
    shared actual native("jvm")
    Character? getFromFirst(Integer index) {
        try {
            return builder.codePointAt(startIndex(index))
                          .character;
        }
        catch (IndexOutOfBoundsException ioobe) {
            return null;
        }
    }
    
    shared native("jvm") 
    StringBuilder append(String string) {
        builder.append(string);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder prepend(String string) {
        builder.insert(0, string);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder appendCharacter(Character character) {
        builder.appendCodePoint(character.integer);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder prependCharacter(Character character) {
        builder.insert(0, toChars(character.integer));
        return this;
    }
    
    shared native("jvm") 
    StringBuilder clear() {
        builder.setLength(0);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder insert(Integer index, String string) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        builder.insert(startIndex(index), string);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder insertCharacter
            (Integer index, Character character) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        builder.insert(startIndex(index),
            toChars(character.integer));
        return this;
    }
    
    shared native("jvm") 
    StringBuilder replace
            (Integer index, Integer length, String string) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        "index+length must not be greater than size"
        assert (index+length<=size);
        Integer len = length<0 then 0 else length;
        Integer start = startIndex(index);
        Integer end = endIndex(start, len);
        builder.replace(start, end, string);
        return this;
    }
    
    shared native("jvm") 
    StringBuilder delete(Integer index, Integer length) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        "index+length must not be greater than size"
        assert (index+length<=size);
        if (length>0) {
            Integer start = startIndex(index);
            Integer end = endIndex(start, length);
            builder.delete(start, end);
        }
        return this;
    }
    
    shared native("jvm") 
    StringBuilder deleteInitial(Integer length) {
        "length must not be greater than size"
        assert (length<=size);
        if (length>0) {
            builder.delete(0, startIndex(length));
        }
        return this;
    }
    
    shared native("jvm") 
    StringBuilder deleteTerminal(Integer length) {
        "length must not be greater than size"
        assert (length<=size);
        if (length>0) {
            Integer start = startIndex(size - length);
            builder.delete(start, builder.length());
        }
        return this;
    }
    
    shared native("jvm") 
    StringBuilder reverseInPlace() {
        builder.reverse();
        return this;
    }
    
    shared actual native("jvm")
    Integer? firstInclusion(List<Character> sublist,
        Integer from) {
        try {
            value start 
                    = builder.offsetByCodePoints(0, 
                            from>0 then from else 0);
            value index 
                    = builder.indexOf(String(sublist), 
                            start);
            return index>=0 
                then from 
                    + builder.codePointCount(start, index);
        }
        catch (IndexOutOfBoundsException ioe) {
            return null;
        }
    }
    
    shared actual native("jvm")
    Integer? lastInclusion(List<Character> sublist,
        Integer from) {
        try {
            value start 
                    = builder.offsetByCodePoints(
                            builder.length(), 
                            (from>0 then -from else 0)
                                - sublist.size);
            value index 
                    = builder.lastIndexOf(String(sublist), 
                            start);
            return index>=0 
                then builder.codePointCount(0, index);
        }
        catch (IndexOutOfBoundsException ioe) {
            return null;
        }
    }
    
    shared actual native("jvm")
    Integer? firstOccurrence(Character character,
        Integer from, Integer length) {
        if (length<=0) { return null; }
        try {
            value start 
                    = builder.offsetByCodePoints(0, 
                            from>0 then from else 0);
            value index 
                    = builder.indexOf(character.string, 
                            start);
            if (index>=0) {
                value count  //TODO: wrong if from<0
                        = builder.codePointCount(start, index);
                return count < length
                    then from + count 
                    else null;
            }
            else {
                return null;
            }
        }
        catch (IndexOutOfBoundsException ioe) {
            return null;
        }
    }
    
    shared actual native("jvm")
    Integer? lastOccurrence(Character character,
        Integer from, Integer length) {
        if (length<=0) { return null; }
        try {
            value start 
                    = builder.offsetByCodePoints(
                            builder.length(), 
                            (from>0 then -from else 0) - 1);
            value index 
                    = builder.lastIndexOf(character.string, 
                            start);
            if (index>=0) {
                value count = //TODO: wrong if from<0
                        builder.codePointCount(index, start);
                return count < length 
                    then builder.codePointCount(0, index)
                    else null;
            }
            else {
                return null;
            }
        }
        catch (IndexOutOfBoundsException ioe) {
            return null;
        }
    }
    
    shared actual native("jvm")
    {Integer*} inclusions(List<Character> sublist, 
        Integer from)
            //TODO: optimize this!
            => string.inclusions(sublist, from);
    
    shared actual native("jvm")
    {Integer*} occurrences(Character character, 
        Integer from, Integer length)
            //TODO: optimize this!
            => string.occurrences(character, from, length);
    
    shared actual native("jvm")
    String measure(Integer from, Integer length) {
        value len = size;
        if (from >= len || length <= 0) {
            return "";
        }
        value resultLength 
                = if (from + length > len) 
                then len - from 
                else length;
        value start = startIndex(from);
        value end = endIndex(start, resultLength);
        return builder.substring(start, end);
    }
    
    shared actual native("jvm") 
    String span(Integer from, Integer to) {
        value len = size;
        if (len == 0) {
            return "";
        }
        value reverse = to < from;
        Integer _to;
        Integer _from;
        if (reverse) {
            _to = from;
            _from = to;
        }
        else {
            _to = to;
            _from = from;
        }
        if (_to < 0 || _from >= len) {
            return "";
        }
        value begin = _from < 0 then 0 else _from;
        value start = startIndex(begin);
        String result;
        if (_to >= len) {
            result = builder.substring(start);
        }
        else {
            value end = endIndex(start, _to+1 - begin);
            result = builder.substring(start, end);
        }
        return reverse then result.reversed else result;
    }
    
    shared actual native("jvm") 
    String spanFrom(Integer from) {
        if (from <= 0) {
            return string;
        }
        value len = size;
        if (len == 0 || from >= len) {
            return "";
        }
        return builder.substring(startIndex(from));
    }
    
    shared actual native("jvm") 
    String spanTo(Integer to) {
        value len = size;
        if (len == 0 || to < 0) {
            return "";
        }
        if (to >= len) {
            return string;
        }
        return builder.substring(0, startIndex(to+1));
    }
    
    shared actual native("jvm") Boolean equals(Object that) 
            => builder.equals(that);
    
    shared actual native("jvm") Integer hash 
            => builder.hash;
    
    Integer startIndex(Integer index) 
            => builder.offsetByCodePoints(0, index);
    
    Integer endIndex(Integer start, Integer length) 
            => builder.offsetByCodePoints(start, length);
    
}

shared native("js") final class StringBuilder() 
        satisfies SearchableList<Character> {
    
    shared actual native("js") variable String string = "";
        
    shared actual native("js") Integer size => string.size;
    
    shared actual native("js") Integer? lastIndex 
            => if (string.size == 0)
            then null
            else string.size - 1;
    
    shared actual native("js") 
    Iterator<Character> iterator() 
            => string.iterator();
    
    shared actual native("js")
    String measure(Integer from, Integer length)
            => string[from:length];
    
    shared actual native("js")
    String span(Integer from, Integer to) => string[from:to];
    
    shared actual native("js")
    String spanTo(Integer to) => string[...to];
    
    shared actual native("js")
    String spanFrom(Integer from) => string[from...];
    
    shared actual native("js")
    Character? getFromFirst(Integer index) 
            => string.getFromFirst(index);
    
    shared native("js") 
    StringBuilder append(String string) {
        this.string = this.string + string;
        return this;
    }
    
    shared native("js") 
    StringBuilder prepend(String string) {
        this.string = string + this.string;
        return this;
    }
    
    shared native("js") 
    StringBuilder appendCharacter(Character character) {
        string = string + character.string;
        return this;
    }
    
    shared native("js") 
    StringBuilder prependCharacter(Character character) {
        string = character.string + string;
        return this;
    }
    
    shared native("js") 
    StringBuilder clear() {
        string = "";
        return this;
    }
    
    shared native("js") 
    StringBuilder insert(Integer index, String string) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        this.string 
                = this.string[0:index] 
                + string 
                + this.string[index...];
        return this;
    }
    
    shared native("js") 
    StringBuilder insertCharacter
            (Integer index, Character character) 
            => insert(index, character.string);
    
    shared native("js") 
    StringBuilder replace
            (Integer index, Integer length, String string) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        "index+length must not be greater than size"
        assert (index+length<=size);
        value len = length<0 then 0 else length;
        this.string 
                = this.string[0:index] 
                + string + 
                this.string[index+len...];
        return this;
    }
    
    shared native("js") 
    StringBuilder delete(Integer index, Integer length) {
        "index must not be negative"
        assert (index>=0);
        "index must not be greater than size"
        assert(index<=size);
        "index+length must not be greater than size"
        assert (index+length<=size);
        if (length>0) {
            string = string[0:index] 
                    + string[index+length...];
        }
        return this;
    }
    
    shared native("js") 
    StringBuilder deleteInitial(Integer length) {
        "length must not be greater than size"
        assert (length<=size);
        if (length>0) {
            string = string[length...];
        }
        return this;
    }
    
    shared native("js") 
    StringBuilder deleteTerminal(Integer length) {
        "length must not be greater than size"
        assert (length<=size);
        if (length>0) {
            string = string[0:size-length];
        }
        return this;
    }
    
    shared native("js") 
    StringBuilder reverseInPlace() {
        string = string.reversed;
        return this;
    }
    
    shared actual native("js")
    Integer? firstInclusion(List<Character> sublist,
        Integer from) 
            => string.firstInclusion(sublist, from);
    
    shared actual native("js")
    Integer? lastInclusion(List<Character> sublist,
        Integer from) 
            => string.lastInclusion(sublist, from);
    
    shared actual native("js")
    Integer? firstOccurrence(Character character,
        Integer from, Integer length) 
            => string.firstOccurrence(character, from, length);
    
    shared actual native("js")
    Integer? lastOccurrence(Character character,
        Integer from, Integer length) 
            => string.lastOccurrence(character, from, length);
    
    shared actual native("js")
    {Integer*} inclusions(List<Character> sublist, 
        Integer from)
            => string.inclusions(sublist, from);
    
    shared actual native("js")
    {Integer*} occurrences(Character character, 
        Integer from, Integer length)
            => string.occurrences(character, from, length);
    
    shared actual native("js") Boolean equals(Object that) 
            => string.equals(that);
    
    shared actual native("js") Integer hash => string.hash;
}

native("dart") shared final class StringBuilder()
        satisfies SearchableList<Character> {

    value delegate = DStringBufferClass();

    native("dart") shared actual Integer size => delegate.string.size;

    native("dart") shared actual Integer? lastIndex
        =>  if (!empty)
            then size - 1
            else null;

    native("dart") shared actual String string
        =>  delegate.string;

    native("dart") assign string {
        clear();
        append(string);
    }

    native("dart") shared actual Iterator<Character> iterator()
        =>  string.iterator();

    native("dart") shared
    String substring(Integer index, Integer length)
        =>  string.measure(index, length);

    native("dart") shared actual
    String measure(Integer from, Integer length)
        =>  string[from:length];
    
    native("dart") shared actual
    String span(Integer from, Integer to)
        =>  string[from:to];
    
    native("dart") shared actual
    String spanTo(Integer to)
        =>  string[...to];
    
    native("dart") shared actual
    String spanFrom(Integer from)
        =>  string[from...];

    native("dart") shared actual
    Character? getFromFirst(Integer index)
        =>  string.getFromFirst(index);

    native("dart") shared
    StringBuilder append(String string) {
        delegate.write(string);
        return this;
    }

    native("dart") shared
    StringBuilder appendAll({String*} strings) {
        for (s in strings) {
            append(s);
        }
        return this;
    }

    native("dart") shared
    StringBuilder prepend(String string) {
        value newString = string + this.string;
        clear();
        delegate.write(newString);
        return this;
    }

    native("dart") shared
    StringBuilder prependAll({String*} strings) {
        for (s in strings) {
            prepend(s);
        }
        return this;
    }

    native("dart") shared
    StringBuilder appendCharacter(Character character) {
        delegate.write(character);
        return this;
    }

    native("dart") shared
    StringBuilder prependCharacter(Character character) {
        prepend(character.string);
        return this;
    }

    native("dart") shared
    StringBuilder appendNewline() => appendCharacter('\n');

    native("dart") shared
    StringBuilder appendSpace() => appendCharacter(' ');

    native("dart") shared
    StringBuilder clear() {
        delegate.clear();
        return this;
    }

    native("dart") shared
    StringBuilder insert(Integer index, String string) {
        "index must not be negative"
        assert (index >= 0);

        "index must not be greater than size"
        assert (index < size);

        value oldString = this.string;

        clear();
        delegate.write(oldString.spanTo(index - 1) + string + oldString.spanFrom(index));
        return this;
    }

    native("dart") shared
    StringBuilder insertCharacter(Integer index, Character character)
        =>  insert(index, character.string);

    native("dart") shared
    StringBuilder replace(Integer index, Integer length, String string) {
        "index must not be negative"
        assert (index > 0);

        "index must not be greater than size"
        assert (index <= size);

        "index+length must not be greater than size"
        assert (index + length <= size);

        if (!string.empty) {
            value oldString = this.string;

            clear();
            delegate.write(oldString.spanTo(index - 1) + string
                + oldString.spanFrom(index + length));
        }
        return this;
    }

    native("dart") shared
    StringBuilder delete(Integer index, Integer length/*=1*/) {
        "index must not be negative"
        assert (index >= 0);

        "index must not be greater than size"
        assert (index < size);

        "index+length must not be greater than size"
        assert (index + length <= size);

        value oldString = this.string;

        clear();
        delegate.write(oldString.spanTo(index - 1) + oldString.spanFrom(index + length));
        return this;
    }

    native("dart") shared
    StringBuilder deleteInitial(Integer length) {
        "length must not be greater than size"
        assert (length <= size);

        if (length > 0) {
            return delete(0, length);
        }
        else {
            return this;
        }
    }

    native("dart") shared
    StringBuilder deleteTerminal(Integer length) {
        "length must not be greater than size"
        assert (length <= size);

        if (length > 0) {
            return delete(size - length, length);
        }
        else {
            return this;
        }
    }

    native("dart") shared
    StringBuilder reverseInPlace() {
        value oldString = this.string;
        clear();
        delegate.write(oldString.reversed);
        return this;
    }

    native("dart") shared actual
    Integer? firstInclusion(List<Character> sublist, Integer from)
        =>  string.firstInclusion(sublist, from);

    native("dart") shared actual
    Integer? lastInclusion(List<Character> sublist, Integer from)
        =>  string.lastInclusion(sublist, from);

    native("dart") shared actual
    Integer? firstOccurrence(Character character, Integer from, Integer length)
        =>  string.firstOccurrence(character, from, length);

    native("dart") shared actual
    Integer? lastOccurrence(Character character, Integer from, Integer length)
        =>  string.lastOccurrence(character, from, length);

    native("dart") shared actual
    {Integer*} inclusions(List<Character> sublist, Integer from)
        =>  string.inclusions(sublist, from);

    native("dart") shared actual
    {Integer*} occurrences(Character character, Integer from, Integer length)
        =>  string.occurrences(character, from, length);

    native("dart") shared actual
    Boolean equals(Object that)
        =>  if (is StringBuilder that)
            then delegate.equals(that.delegate)
            else false;

    native("dart") shared actual
    Integer hash => delegate.hash;
}
