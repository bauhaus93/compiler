#!/bin/bash

cd ..
make
./gesamt < test/test.0 > test/test.s
cd test
gcc test.c test.s -o test -ggdb
./test
