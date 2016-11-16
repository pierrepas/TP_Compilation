#!/bin/sh

LLC=llc

# compile le test de la sémantique de la calculatrice, en bytecode
# (calc_test_sem.byte)
echo ========================
echo  Compilation test
echo ========================
ocamlbuild -j 4 -pp pa_ocaml calc_test_sem.byte || exit 1

# execute le test
echo ========================
echo  Test de la sémantique
echo ========================
./calc_test_sem.byte

# compile la calculatrice, en bytecode (calc.byte) et
# et en code natif (calc.native)
echo ========================
echo  Compilation complète
echo ========================
ocamlbuild -j 4 -pp pa_ocaml -pkgs earley,earley.str,unix calc.native calc.byte || exit 1

# execute l'exemple
echo ========================
echo  Test sémantique+parser
echo ========================
./calc.native < calc_tests/test.txt

# compile l'exemple
echo ========================
echo    Test compilateur
echo ========================
./calc.native -c < calc_tests/test.txt > calc_tests/test.ll || exit 1
$LLC -march=x86-64 -relocation-model=pic calc_tests/test.ll || exit 1
as -march=core2 --64 -c calc_tests/test.s -o calc_tests/test.o || exit 1
gcc -march=core2 -m64 calc_tests/test.o -o calc_tests/test.exe || exit 1

# execute l'exemple
calc_tests/test.exe
