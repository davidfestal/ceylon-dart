library runnerLib;

import "dart:core" as $dart$core;
import "../ceylon-dart-language/build/modules-dart/main/ceylon/language/1.2.2-DP2/ceylon.language-1.2.2-DP2.dart" as $ceylon$language;

void main(var arguments) {
    $ceylon$language.initializeProcess(arguments);
    run();
}

//////////////////////////////////
//
// Paste compiled dart code below
//
//////////////////////////////////

void $package$run() {
    $ceylon$language.print($ceylon$language.String.instance("hello"));
}

void run() => $package$run();
