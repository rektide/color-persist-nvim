# nvim-color-persist Plugin

OpenCode plugin to automatically persist and restore Neovim colorschemes.

## Overview

This plugin watches for Neovim theme changes and automatically switches OpenCode's theme to match, providing a cohesive development experience.

## How OpenCode Themes Work

### Theme Loading Flow (5 Steps)

1. **Config File Check** - Reads `opencode.json` for `theme` field
   - Path: Project root `opencode.json` or global `~/.config/opencode/opencode.json`
   - Supports JSON and JSONC formats

2. **KV Store Fallback** - If no config theme, checks persisted state
   - Path: `~/.config/opencode/kv.json`
   - Key: `"theme"`

3. **Default Fallback** - Uses `"opencode"` theme if neither exists

4. **Custom Themes Load** - Loads custom themes from directories (in order of priority)
   - Built-in themes (embedded in binary)
   - Global: `~/.config/opencode/themes/*.json`
   - Project: `<project-root>/.opencode/themes/*.json`
   - CWD: `./.opencode/themes/*.json`

5. **Theme Resolution** - Applies selected theme with dark/light mode
   - Resolves color references (e.g., `"primary"`, `"nord0"`)
   - Handles dark/light variants: `{ "dark": "#000", "light": "#fff" }`
   - Supports hex colors, ANSI codes (0-255), and `"none"` (terminal default)

### Changing Themes

**From TUI**:
- Command: `/theme`
- Keybind: `Ctrl+X T`
- Opens `DialogThemeList` for interactive selection

**Programmatically** (via SDK):
```typescript
// PATCH /config endpoint
await client.config.update({ theme: "tokyonight" })
```

**Via config file**:
- Set `theme` field in `opencode.json`
- Takes precedence over KV store on next load

### Built-in Theme Names

- `system` - Adapts to terminal colors
- `tokyonight`, `catppuccin`, `catppuccin-macchiato`, `catppuccin-frappe`
- `nord`, `dracula`, `gruvbox`, `ayu`, `everforest`
- `kanagawa`, `solarized`, `monokai`, `matrix`
- `one-dark`, `rosepine`, `palenight`, `zenburn`
- `cobalt2`, `cursor`, `github`, `vercel`
- `mercury`, `nightowl`, `flexoki`, `osaka-jade`
- `orng`, `lucent-orng`, `synthwave84`, `aura`

### Custom Theme Format

Custom themes are JSON files placed in `.opencode/themes/`:

```json
{
  "$schema": "https://opencode.ai/theme.json",
  "defs": {
    "primary": "#89b4fa"
  },
  "theme": {
    "primary": "primary",
    "secondary": "#cba6f7",
    "background": "#1e1e2e",
    "text": "#c0caf5",
    // ... more colors
  }
}
```

Full schema: See [Theme Documentation](https://opencode.ai/docs/themes/)

## Plugin Architecture

### Config Hook Strategy

Use the plugin `config` hook to set theme on startup:

```typescript
export const ColorPersistPlugin: Plugin = async (ctx) => {
  return {
    config: async (config) => {
      // Detect Neovim theme
      const nvimTheme = await detectNvimTheme()

      // Set OpenCode theme if different
      if (config.theme !== nvimTheme) {
        await ctx.client.config.update({ theme: nvimTheme })
      }
    }
  }
}
```

**Why this works**:
- The `config` hook runs during OpenCode initialization
- Has access to current config state
- Can call `client.config.update()` to persist changes
- Changes apply before TUI fully initializes

### Plugin Hook Limitations

Plugins **cannot**:
- Access TUI theme context (`useTheme()` is internal)
- Directly modify KV store
- Trigger theme dialog via SDK
- Execute TUI commands (`tui.command.execute` is receive-only)

Plugins **can**:
- Call `client.config.update({ theme: "..." })`
- Receive `config` hook on load
- Watch for Neovim changes and react

## Available Theme Names Mapping

Common Neovim themes → OpenCode themes:

| Neovim Theme | OpenCode Theme |
|---------------|----------------|
| tokyonight.nvim | tokyonight |
| catppuccin.nvim | catppuccin |
| nordic.nvim | nord |
| dracula.nvim | dracula |
| gruvbox.nvim | gruvbox |
| everforest.nvim | everforest |
| kanagawa.nvim | kanagawa |
| solarized.nvim | solarized |
| onedark.vim | one-dark |

For unmapped themes, the plugin will need to either:
1. Create a matching custom theme in `.opencode/themes/`
2. Fall back to a similar built-in theme
3. Use `system` theme to match terminal colors

## Development

### Files

- `.opencode/plugin/nvim-color-persist.ts` - Main plugin entry
- `.opencode/themes/*.json` - Custom theme definitions (optional)
- `opencode.json` - Config with theme override (optional)

### Testing

```bash
# Reload OpenCode to trigger config hook
opencode

# Check current theme
cat ~/.config/opencode/kv.json

# Set theme manually via API
curl -X PATCH http://localhost:4096/config \
  -H "Content-Type: application/json" \
  -d '{"theme": "tokyonight"}'
```

### Debug Logging

```typescript
console.log("Detected Neovim theme:", nvimTheme)
console.log("Current OpenCode config:", config)
console.log("Setting theme:", newTheme)
```

## Alternatives Considered

1. **KV Store Direct Write** - Write to `~/.config/opencode/kv.json` directly
   - ✅ Works, but hacky
   - ❌ Bypasses config system
   - ❌ Doesn't persist through config merge

2. **HTTP PATCH /config** - Call OpenCode server API
   - ✅ Clean approach
   - ✅ Properly merges config
   - ✅ Respects config priority
   - ⚠️  Requires server to be running

3. **Watch for theme events** - Listen for `tui.theme.changed` (hypothetical)
   - ❌ No such event exists
   - ❌ Plugin hooks don't include TUI state changes

4. **Neovim-side integration** - Write from Neovim to OpenCode socket
   - ✅ Real-time sync
   - ❌ More complex
   - ❌ Requires OpenCode client running

**Winner**: Config hook with `client.config.update()`

## Implementation Notes

### Theme Name Normalization

Neovim themes may have different naming conventions:
- `tokyonight-night` → `tokyonight`
- `catppuccin-mocha` → `catppuccin`
- `nord.vim` → `nord`

Plugin should normalize detected theme names to match available OpenCode themes.

### Error Handling

```typescript
try {
  await ctx.client.config.update({ theme: detectedTheme })
} catch (error) {
  if (error.message.includes("not found")) {
    console.warn(`Theme "${detectedTheme}" not available, falling back to system`)
    await ctx.client.config.update({ theme: "system" })
  } else {
    console.error("Failed to set theme:", error)
  }
}
```

### Performance

- Config hook runs once at startup (fast)
- No polling needed - uses config system
- Theme change persists across OpenCode restarts

## Future Enhancements

- [ ] Auto-generate OpenCode themes from Nevim color definitions
- [ ] Watch for Neovim theme changes and auto-update
- [ ] Handle gradient/dynamic themes
- [ ] Support multiple theme profiles (e.g., day/night mode)
