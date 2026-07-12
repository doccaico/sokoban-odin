## Simple Sokoban (倉庫番)

[Play](https://doccaico.github.io/sokoban-odin/)

### User guide
- [Space, Enter] enter
- [Up, W] move up
- [Down, S] move down
- [Left, A] move left
- [Right, D] move right
- [R] retry
- [B] back

### Desktop Build
```sh
# build
$ call build_desktop.bat
# run
$ .\build\desktop\game_desktop.exe

# or
$ call build_desktop.bat && .\build\desktop\game_desktop.exe

# release
$ call build_desktop.bat --release
```
### Web Build
```sh
# build
$ build_web.bat
# run
$ python -m http.server

# Go to localhost:8000 in your browser

# release
$ call build_web.bat --release
```
