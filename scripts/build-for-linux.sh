#!/bin/bash

cmake -S . -B /home/im/Documents/SIGPACGOEDITS/TESTUI-master/build-x64-linux -GNinja -DWITH_VCPKG=ON -DWITH_SPIX=ON -DENABLE_TESTS=ON
cmake --build /home/im/Documents/SIGPACGOEDITS/TESTUI-master/build-x64-linux
