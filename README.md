# project-color

Help users pick preferred themes for their projects.

## About

`project-color` is a collection of tools and plugins that help you maintain consistent color themes across your projects and development tools.

## Components

### project-color-nvim

A Neovim plugin that persists your current theme to a `.env.editor` file, allowing you to maintain consistent color schemes across different projects and sessions.

**Installation:**

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'rektide/project-color',
  config = function()
    require('project-color-nvim').setup()
  end
}
```

For full documentation, see [nvim/README.md](nvim/README.md).

## Usage

The project-color system uses environment variables to store theme preferences:

- `EDITOR_COLOR` - General theme preference for editors
- `NVIM_COLOR` - Neovim-specific theme override

These can be set:
- In a `.env.editor` file in your project root
- As system environment variables
- Automatically persisted when using project-color-nvim

## License

MIT
