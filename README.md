# love-jam-2024

This is the project for [Love-Jam-2024](https://itch.io/jam/love2d-jam-2024)

## For developers
### Getting started
1. [Fork the repo](https://github.com/EngineerSmith/love-jam-2024/fork)
2. Clone your fork to your machine!
3. Open the repo in your love2d developing environment of choice

4. Make sure you're using latest love 12 ([get it from here](https://github.com/love2d/love/actions/runs/7895106111#artifacts))
   * Download, and put into your love directory. You may want to temporarily move your current install into a subfolder so you can switch to it again after the jam
5. Open the directory in file explorer, and in the address bar type `cmd` to open a console
6. To run the project, type `love .` into the console. You can add `--speed` after the period to skip the intro scene
   * `love . --speed`

Now I recommend you get use to the code base by looking around. I first recommend to check out how the chat is implement. Key files can be found at `coordinator.chat` and `scenes.game.ui.chat`. Use this system as a base of how you should write, and design systems for the game.

### Contributing
To ensure the jam goes smoothly, and to make sure the project doesn't die to bugs. When you make a pull request, it will have to reviewed by at least 1 other person before being accepted.

If you're doing a code review. First understanding what the pull request is trying to add to the project. Then read through the code to find out how it achieves that objective. Add insightful comments if you notice any bugs, missed edge cases, or issues on how they could be solved.

## Assets
To add new assets, you can put them in the `assets` directory. Then you can add it to the `assets/assets.lua` which lists all assets. You may have to create a subdirectory, to ensure it is correctly sorted.

* `path` is the file path, within the `assets` directory
* `name` is the unique keyword you will use to access the asset within the project with
* `onLoad` is a function that is called after the asset has been loaded (see `pixelArt`)

Fonts, are a little different; so talk to EngineerSmith for help with that system.

To access your newly added asset within a lua file. It's quite simple. They are loaded for you; so don't worry about handling the lifetime of the asset.
```lua
local assets = require("util.assets")
assets[name]
```

### For developers
Check out `util.lilyloader` for how it uses lily and extensions to determines which function to use to load an asset.

## Arguments
There are a few arguments that you can use to speed up development. These are used when you run the program. The ones to remember are: `love . --speed` for the client, and for the server `love . --server`. These work with the fused project too `love-jam-2024.exe --speed`

* `--speed` Will skip the intro-scenes, as soon as all assets are loaded.
* `--server` Used to start a server instead of a client
* `--log [file name: log.txt]` will add a logging sink, to save logs
  * e.g. `--log` saves to save_directory/log.txt, `--log mylogs.txt` saves to save_directory/mylogs.txt
* `--settings <file name>` used to use a different file for settings than the default save_directory/settings.json

### How to use arguments
```lua
local args = require("util.args")

-- no arguments, will just make it a boolean
args["--keyword"]
-- if it has arguments, it will be a table array
local var = "default"
if type(args["--keyword"]) == "table" then
  var = args["--keyword"][1]
end
```

## Language
You can add language keys to `en.json`, and the access them with the following.
```lua
local lang = require("util.lang")
local str = lang.getText("my.key")
-- for text, with variables
  -- e.g. 'my.key': 'My cat's name is $1. $2 $1'
local str = lang.getText("my.key", 'Pizza', 'I love') -- 'My cat's name is Pizza. I love Pizza'
```

## Logging
The project includes a basic logging system
```lua
local logger = require("util.logger")

-- Logger contains a few basic functions. The different levels, just use different prefixes and colors (where consoles support colors)
logger.info()
logger.warn()
logger.error()
logger.fatal() -- fatal, will show a message box and close the program
logger.unknown()

-- They all work similar to print, in that they can take in multiple values
logger.info("What have I done wrong", type(variable1), variable1)

-- Note, if you call print()
-- it will redirect to logger.unknown
```