import dart.collection {
    DoubleLinkedQueue
}

"A queue with a native implementation"
native class NativeDeque() {
    shared native void pushFront(Anything element);
    shared native void pushBack(Anything element);
    shared native Anything popFront();
    shared native Boolean empty;
    shared actual native String string;
}

native("jvm") class NativeDeque() {
    import java.util {
        ArrayDeque,
        Deque
    }

    Deque<Anything> deque = ArrayDeque<Anything>();
    shared native("jvm") void pushFront(Anything element) {
        deque.addFirst(element);
    }
    shared native("jvm") void pushBack(Anything element) {
        deque.addLast(element);
    }
    shared native("jvm") Anything popFront() {
        return deque.pollFirst();
    }
    shared native("jvm") Boolean empty {
        return deque.empty;
    }
    shared actual native("jvm") String string {
        return deque.string;
    }
}

native("js") class NativeDeque() {
    dynamic deque;
    dynamic {
        deque=dynamic[null];
        deque.shift();
    }
    shared native("js") void pushFront(Anything element) {
        dynamic {
            deque.unshift(element);
        }
    }
    shared native("js") void pushBack(Anything element) {
        dynamic {
            deque.push(element);
        }
    }
    shared native("js") Anything popFront() {
        dynamic {
            if (deque.length==0) {
                return null;
            }
            return deque.shift();
        }
    }
    shared native("js") Boolean empty {
        dynamic {
            return deque.length==0;
        }
    }
    shared actual native("js") String string {
        value sb=StringBuilder();
        sb.append("[");
        dynamic {
            for (i in 0:deque.length) {
                if (sb.size > 1) {
                    sb.append(", ");
                }
                sb.append(deque[i]);
            }
        }
        sb.append("]");
        return sb.string;
    }
}

native("dart") class NativeDeque() {
    value deque = DoubleLinkedQueue<Anything>.Class();

    shared native("dart") void pushFront(Anything element)
        =>  deque.addFirst(element);

    shared native("dart") void pushBack(Anything element)
        =>  deque.addLast(element);

    shared native("dart") Anything popFront()
        =>  deque.removeFirst();

    shared native("dart") Boolean empty
        =>  deque.isEmpty;

    shared actual native("dart") String string
        =>  deque.string;
}
