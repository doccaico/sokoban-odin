## Simple Sokoban (倉庫番)

[Play](https://doccaico.github.io/sokoban-odin/)

### User guide
- [Space, Enter] enter
- [Up, W] move up
- [Down, S] move down
- [Left, A] move left
- [Right, D] move right
- [R] retry
- [U] undo
- [T] back to title
- [Esc] exit

### Desktop Build
```sh
# build
$ build_desktop.bat
# run
$ build\desktop\game_desktop.exe

# build and run in one line
$ call build_desktop.bat && build\desktop\game_desktop.exe

# debug build (for checking memory leaks)
$ build_desktop.bat --debug

# release build
$ build_desktop.bat --release
```
### Web Build
```sh
# build
$ build_web.bat
# go to localhost:8000 in your browser
$ python -m http.server

# release build
$ build_web.bat --release
```
