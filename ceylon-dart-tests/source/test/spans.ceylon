//#20
@test
shared void spanmeasures() {
  check(6..4==[6,5,4], "range vs sequence");
  value one9 = "123456789";
  check((1..20).span(5,3)==6..4, "Backward span [1] was ``(1..20).span(5,3)``");
  check([1,2,3,4,5,6,7,8,9].span(5,3)==[6,5,4], "Backward span [2] was ``[1,2,3,4,5,6,7,8,9].span(5,3)``");
  check(one9.span(5,3)=="654", "Backward span [3] ``one9.span(5,3)``");
  check(Array{1,2,3,4,5,6,7,8,9}.span(5,3)=={6,5,4}.sequence(), "Backward span [4] was ``Array{1,2,3,4,5,6,7,8,9}.span(5,3)``");
  check(LazyList({1,2,3,4,5,6,7,8,9}).span(5,3)=={6,5,4}.sequence(), "Backward span [5] was ``LazyList({1,2,3,4,5,6,7,8,9}).span(5,3)``");

  check((1..20).measure(1,-1).sequence()=={}, "Backward measure [1] ``(1..20).measure(1,-1).sequence()``");
  check([1,2,3,4,5,6,7,8,9].measure(1,-1)=={}, "Backward measure [2] ``[1,2,3,4,5,6,7,8,9].measure(1,-1)``");
  check(one9.measure(1,-1)=="", "Backward measure [3] ``one9.measure(1,-1)``");
  check(Array{1,2,3,4,5,6,7,8,9}.measure(1,-1)=={}, "Backward measure [4] ``Array{1,2,3,4,5,6,7,8,9}.measure(1,-1)``");
  check(LazyList({1,2,3,4,5,6,7,8,9}).measure(1,-1)=={},
        "Backward measure [5] ``LazyList({1,2,3,4,5,6,7,8,9}).measure(1,-1)``");

  check("hello"[-1..10]=="hello", "string span out of range");
  check("hello".sequence()[-1..10]=={ 'h', 'e', 'l', 'l', 'o' }.sequence(), 
        "string sequence span out of range: ``("hello".sequence()[-1..10])`` expected { \'h\', \'e\', \'l\', \'l\', \'o\' }");
  check([1,2,3][-1..10]=={1,2,3}.sequence(), "sequence span out of range");
  check((1..5)[-1..10]==1..5, "range out of range");
  check(Singleton(0)[-1..10]==Singleton(0), "singleton out of range");
    
  check("hello"[10..-10]=="olleh", "backward string span out of range");
  check("hello".sequence()[10..-10]=={ 'o', 'l', 'l', 'e', 'h' }.sequence(), 
        "backward string sequence span out of range: ``("hello".sequence()[10..-10])`` expected { \'o\', \'l\', \'l\', \'e\', \'h\' }");
  check([1,2,3][10..-10]=={3,2,1}.sequence(), "backward sequence span out of range");
  check((1..5)[10..-10]==5..1, "backward range out of range");
  check(Singleton(0)[10..-10]==Singleton(0), "backward singleton out of range");
  
  check("hello"[-1..1]=="he", "string span neg start");
  check("hello".sequence()[-1..1]=={ 'h', 'e' }.sequence(),
        "string sequence span neg start: ``("hello".sequence()[-1..1])`` expected { \'h\', \'e\' }");
  print([1,2,3][-1..1]);
  check([1,2,3][-1..1]=={1,2}.sequence(), "sequence span neg start");
  check((1..5)[-1..1]==1..2, "range span neg start");
  check(Singleton(0)[-1..1]==Singleton(0), "singleton span neg start");
  
  check("hello"[1..-1]=="eh", "backward string span neg end");
  check("hello".sequence()[1..-1]=={ 'e', 'h' }.sequence(),
        "backward string sequence span neg end: ``("hello".sequence()[1..-1])`` expected { \'e\', \'h\' }");
  check([1,2,3][1..-1]=={2,1}.sequence(),
        "backward sequence span neg end ``[1,2,3][1..-1]`` expecting {2,1}");
  check((1..5)[1..-1]==2..1, "range span neg end");
  check(Singleton(0)[1..-1]==Singleton(0), "singleton span neg end");
}
