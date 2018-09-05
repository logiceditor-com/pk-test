pk-test: the PK testing facilities
================================================================================

## Обзор процедуры установки pk-test

## Перед началом установки
Убедитесь, что:
1. У вас ОС Ubuntu (в данной инструкции используется 16.04).
2. Установлен и настроен git (см. [Development guidelines](https://github.com/logiceditor-com/coding-guidelines/blob/master/development-guidelines.md#%D0%9A%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F))
3. Установлена Lua 5.1 (`sudo apt-get install lua5.1 liblua5.1-dev`).
4. Установлен LuaRocks (`sudo apt-get install luarocks`).
5. У вас есть отдельная директория для клонирования проектов и работы с ними (в дальнейшем предполагается, что это директория "projects": `mkdir -p ~/projects/`).

## Последовательность установки
Для корректной работы pk-test нужно установить следующие "камни" и пакеты:
1. pk-test
2. luaposix 31-1
3. MySQL (для тестов в pk-engine)

# Установка pk-test
1. Установите wsapi-xavante (`sudo luarocks install wsapi-xavante`).

2. Клонируйте проект le-tools и установите le-tools.le-call-lua-module при помощи rockspec-файлов:

        cd ~/projects
        git clone https://github.com/logiceditor-com/le-tools.git
        cd le-tools
        sudo luarocks make rockspec/le-tools.le-lua-interpreter-scm-1.rockspec
        sudo luarocks make rockspec/le-tools.le-call-lua-module-scm-1.rockspec

3. Клонируйте проект pk-test и установите его при помощи rockspec-файла:

        cd ~/projects
        git clone git@github.com:logiceditor-com/pk-test.git
        cd pk-test
        sudo luarocks make rockspec/pk-test-scm-1.rockspec

# Установка luaposix 31-1

Обратите внимание: с более новой версией luaposix тесты запускаться не будут!

    sudo luarocks install luaposix 31-1

# Установка и настройка MySQL (для тестов в pk-engine)

Установите mysql-server (в процессе установки введите пароль "12345"):

    sudo apt-get install mysql-server

Установите mysql-client:

    sudo apt-get install mysql-client

Создайте базу данных `pk-test`:

    mysql -uroot -p12345 -e 'create database `pk-test`'

# Установка Luasocket

Важно отметить, что Luarocks на Unix-система ставит СТАРУЮ ВЕРСИЮ luasocket, которая не проходит strict-мод у Lua-Nucleo.
Чтобы исправить эту ошибку следует установить Luasocket через apt.

    apt-get install luasocket

# Запуск тестов

Для запуска всех тестов какого-либо проекта (lua-aplicado, pk-core или pk-engine), перейдите в корневую директорию проекта и запустите:

    pk-test

Для запуска какого-либо определённого теста укажите имя lua-файла данного теста (находятся в директории /test/cases):

    pk-test 0060-http.lua

Можно использовать шаблон имени файла:

    pk-test 0060

Для подробной справки смотрите вывод `pk-test --help`.

## Особенности запуска тестов в lua-nucleo

Вместо pk-test для запуска тестов в lua-nucleo используется `./test.sh`. При этом можно использовать шаблон имени файла, однако знак минуса в шаблоне нужно экранировать с помощью символа процента `%`:

    ./test.sh 0460%-dia

================================================================================

Copyright (c) 2010-2018 LogicEditor <team@logiceditor.com>

See file 'COPYRIGHT' for the license.
