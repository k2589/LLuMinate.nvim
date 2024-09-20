# LLuMinator

LLuMinator is a Neovim plugin that enriches the context of copied code by providing additional information about symbols, such as their definitions and hover information from LSP. This plugin is particularly useful for developers who want to quickly understand and share code snippets with more context to pass it to LLM Chat for example. 

## Features

- Automatically enrich copied code with additional context
- Provide definitions and hover information for symbols
- Configurable options to include/exclude specific information types
- Intelligent filtering of common keywords and types to reduce clutter
- Works seamlessly with Neovim's built-in LSP

[![asciicast](https://asciinema.org/a/NBBjSCmRnlLl7T7pHtT7lEBJN.svg)](https://asciinema.org/a/NBBjSCmRnlLl7T7pHtT7lEBJN)

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

Add the following line to your Neovim configuration:

```lua
use {
  'k2589/LLuMinator.nvim',
  config = function()
    require('lluminator').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your Neovim configuration:

```lua
{
  'k2589/LLuMinator.nvim',
  config = function()
    require('lluminator').setup()
  end
}
```

## Configuration

LLuMinator comes with default settings, but you can customize its behavior. Here's an example of how to configure the plugin:

```lua
require('lluminator').setup({
  include_definition = false,  -- Include symbol definitions in the enriched context
  include_hover = true,       -- Include hover information in the enriched context
})
```

### Default keymaps

```
    normal_mode = '<leader>lm',
    visual_mode = '<leader>lm'

```

### Command
`:EnrichContext`

## Usage

Once installed and configured, LLuMinator will automatically enrich the context of code you copy. Here's how to use it:

1. Select the code you want to copy in visual mode.
2. Use hotkey or command to yank selected (or last selected in normal mode) code
3. LLuMinator will automatically process the copied code and add enriched context.
4. Paste the enriched code wherever you need it (for example to your loved LLM Chat, I use Cloude btw)

### Example

#### Original code:

```go
	someVar := somepackage.SomeFunc(someStructVar.A, someStructVar.B)
	if someVar != nil {
		log.Panic(someVar)
	}
```

#### Enriched context:

	someVar := somepackage.SomeFunc(someStructVar.A, someStructVar.B)
	if someVar != nil {
		log.Panic(someVar)
	}

Additional Context:

Hover of someVar:
```go
var someVar error
```


Hover of somepackage:
```go
package somepackage ("go-example/somePackage")
```

[`somepackage` on pkg.go.dev](https://pkg.go.dev/go-example/somePackage)


Hover of SomeFunc:
```go
func somepackage.SomeFunc(foo int, bar int) error
```

[`somepackage.SomeFunc` on pkg.go.dev](https://pkg.go.dev/go-example/somePackage#SomeFunc)


Hover of someStructVar:
```go
var someStructVar SomeStruct
```


Hover of A:
```go
field A int
```

[`(main.SomeStruct).A` on pkg.go.dev](https://pkg.go.dev/go-example#SomeStruct.A)


Hover of B:
```go
field B int
```

[`(main.SomeStruct).B` on pkg.go.dev](https://pkg.go.dev/go-example#SomeStruct.B)


Hover of nil:
```go
var nil Type	// Type must be a pointer, channel, func, interface, map, or slice type
```

nil is a predeclared identifier representing the zero value for a pointer, channel, func, interface, map, or slice type.


[`nil` on pkg.go.dev](https://pkg.go.dev/builtin#nil)


Hover of log:
```go
package log
```

[`log` on pkg.go.dev](https://pkg.go.dev/log)


Hover of Panic:
```go
func log.Panic(v ...any)
```

Panic is equivalent to \[Print] followed by a call to panic().


[`log.Panic` on pkg.go.dev](https://pkg.go.dev/log#Panic)


## Customization

You can customize LLuMinator's behavior by modifying the `should_process_symbol` function in the plugin's source code. This allows you to add or remove keywords and types that should be skipped during processing.

## Troubleshooting

If you encounter any issues:

1. Ensure your Neovim version is up to date.
2. Check that you have the necessary LSP servers installed and configured.
3. Verify that the plugin is properly installed and loaded.

If problems persist, please open an issue on the GitHub repository.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
