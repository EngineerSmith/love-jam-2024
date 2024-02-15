# love-jam-2024

This is the project for [Love-Jam-2024](https://itch.io/jam/love2d-jam-2024)

## For developers
### Getting started
1. [Fork the repo](https://github.com/EngineerSmith/love-jam-2024/fork)
2. Clone your fork to your machine!
3. Open the repo in your love2d developing environment of choice

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