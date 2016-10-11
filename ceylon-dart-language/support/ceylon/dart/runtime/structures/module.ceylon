"A Supplementary Collections Module for [Ceylon](http://ceylon-lang.org).

 This module was inspired by and adapted from [Google
 Guava](https://github.com/google/guava) under the Apache License Version 2.0.

 Currently implemented types are:

 * [[ArrayListMultimap]]: a mutable `Collection<Key->Item>` and
   `Correspondence` from `Key` to `MutableList<Item>` that supports deterministic
   iteration order for both keys and items.

 * [[LinkedListMultimap]]: a mutable `Collection<Key->Item>` and
   `Correspondence` from `Key` to `MutableList<Item>` that supports deterministic
   iteration order for both keys and items.

 * [[HashMultimap]]: a mutable `Collection<Key->Item>` and
   `Correspondence` from `Key` to `MutableSet<Item>` that does not store duplicate
   `key->item` entries."
module ceylon.dart.runtime.structures "1.3.1-SNAPSHOT" {
    shared import ceylon.dart.runtime.nativecollection "1.3.1-SNAPSHOT";
}
