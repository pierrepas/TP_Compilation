#!/bin/sh

# compile le test de la sémantique de la calculatrice, en bytecode
# (calc_test_sem.byte)
echo ========================
echo  Compilation test
echo ========================
ocamlbuild -pp pa_ocaml calc_test_sem.byte

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
ocamlbuild -pp pa_ocaml -pkgs decap calc.native calc.byte

# execute l'exemple
echo ========================
echo  Test sémantique+parser
echo ========================
./calc.native < calc_tests/test.txt

# compile l'exemple
echo ========================
echo    Test compilateur
echo ========================
./calc.native -c < calc_tests/test.txt > calc_tests/test.ll
llc -march=x86-64 calc_tests/test.ll
as -c calc_tests/test.s -o calc_tests/test.o
gcc calc_tests/test.o -o calc_tests/test.exe

# execute l'exemple
calc_tests/test.exe
