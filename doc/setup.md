# Установка pk-test

(...на машине с Ubuntu raring)

Будьте внимательны. Если стоят другие наши проекты, все или часть пунктов из
этой инструкции могут быть уже выполнены или не актуальны.

## Установить _наш_ luarocks

```
wget -q http://ubuntu.iphonestudio.ru/key.asc -O- | sudo apt-key add -
echo "deb http://ubuntu.iphonestudio.ru unstable main" \
  | sudo tee -a /etc/apt/sources.list.d/ubuntu.iphonestudio.ru.list
sudo apt-get update
sudo apt-get install luarocks
```

## Установить и настроить git

См. [Development guidelines](https://github.com/logiceditor-com/coding-guidelines/blob/master/development-guidelines.md#%D0%9A%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F)

## Установить зависимости

Установить lua-nucleo:

```
sudo luarocks install \
https://raw.github.com/lua-nucleo/lua-nucleo/master/rockspec/\
lua-nucleo-scm-1.rockspec
```

Скачать зависимости pk-*

```
mkdir -p ~/projects
cd ~/projects
git clone gitolite@git.iphonestudio.ru:pk-core
git clone gitolite@git.iphonestudio.ru:pk-engine
git clone gitolite@git.iphonestudio.ru:pk-tools
git clone gitolite@git.iphonestudio.ru:pk-foreign-rocks
git clone gitolite@git.iphonestudio.ru:pk-test
```

В репозитории `pk-foreign-rocks` хранятся все необходимые зависимости для
установки `pk-test`. Некоторые из этих "камней" отсутствуют на сервере
luarocks, поэтому в дальнейшем нужно будет указать luarocks брать пакеты только
из `pk-foreign-rocks`. Для этого можно в каждый вызов `luarocks` добавить
флаг `--only-from=...` указывающий на каталог с "камнями" внутри
`pk-foreign-rocks`. Сохраним этот каталог в переменную `FRR` для последующих
вызовов:

```
FRR=${HOME}/projects/pk-foreign-rocks/rocks
```

Установить lua-aplicado с Гитхаба:

```
sudo luarocks --only-from=${FRR} install \
https://raw.github.com/lua-aplicado/lua-aplicado/master/rockspec/\
lua-aplicado-scm-1.rockspec
```

Установить необходимые пакеты для raring (пароль от рута в mysql должен быть
"12345" -- так надо для тестов в pk-engine):

```
sudo apt-get install libev-dev libzmq-dev uuid-dev libssl0.9.8 mysql-server \
  postgresql redis-server
```

Установить `libmysqlclient16`, которого нет в raring, но есть в lucid:

```
echo "deb http://us.archive.ubuntu.com/ubuntu/ lucid main restricted" \
  | sudo tee -a /etc/apt/sources.list.d/lucid.list
sudo apt-get update
sudo apt-get install libmysqlclient16
```

Устанавливаем остальные камни и pk-test:

```
cd ${HOME}/projects/pk-core
sudo luarocks --only-from=${FRR} make rockspec/pk-core-scm-1.rockspec
cd ${HOME}/projects/pk-engine
sudo luarocks --only-from=${FRR} make rockspec/pk-engine-scm-1.rockspec
cd ${HOME}/projects/pk-tools
sudo luarocks --only-from=${FRR} make \
  rockspec/pk-tools.pk-lua-interpreter-scm-1.rockspec
sudo luarocks --only-from=${FRR} make \
  rockspec/pk-tools.pk-call-lua-module-scm-1.rockspec
cd ${HOME}/projects/pk-test
sudo luarocks --only-from=${FRR} make rockspec/pk-test-scm-1.rockspec
```

**TODO:** Заменить установку `pk-tools.pk-*` на `le-tools.pk-*` когда в
          `pk-test` будут прописаны новые зависимости от `le-tools.pk-*`.
          https://redmine-tmp.iphonestudio.ru/issues/2912

Установить то, что не установилось из-за проблем с зависимостями:

```
sudo luarocks --only-from=${FRR} install luasocket-unix
sudo luarocks --only-from=${FRR} install luasql-postgres
```

**TODO**: Учесть зависимость тестов pk-engine от luasocket-unix и
          luasql-postgres.
          https://redmine-tmp.iphonestudio.ru/issues/3056

## Дополнительно настроить для тестов в `pk-engine`

Создать базу данных `pk-test`:

```
mysql -uroot -p12345 -e 'create database `pk-test`'
```

**TODO**: Как настроить Postgresql?
          https://redmine-tmp.iphonestudio.ru/issues/3055

## Запуск тестов

В проектах lua-aplicado, pk-core и pk-engine:

```
pk-test
```

Если хотим запустить какие-то определённые тесты, можно использовать шаблон
по имени файла:

```
pk-test 0060
pk-test 0060-http.lua
```

Для подробной справки смотрите вывод `pk-test --help`.

### Запуск тестов в `lua-nucleo`

В lua-nucleo `pk-test` не работает.
(См. https://redmine-tmp.iphonestudio.ru/issues/2519)

Чтобызапускать тесты в lua-nucleo, нужно вызывать `./test.sh`. Он тоже
понимает шаблон имени файла, но если в шаблоне есть минус его нужно
заэкранировать с помощью `%`.

```
./test.sh 0460%-dia
```

**TODO**: Исправить необходимость экранировать спецсимволы в шаблонах
          `./test.sh`.
          https://redmine-tmp.iphonestudio.ru/issues/3042
