# My NeoVim Config

Welcome to my neovim config.
I use [packer](https://github.com/wbthomason/packer.nvim) to manage plugins.

To use neovim with this config,
clone the repo into `~/.config` (or whatever your config directory is)
then run the following (copied from the 
[packer quickstart](https://github.com/wbthomason/packer.nvim?tab=readme-ov-file#quickstart)).

```bash
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

Then you'll need to open lua/scripts/packer.lua in neovim and enter

```
:so
:PackerSync
```

and you should be good to go.

Note that PackerSync will revert the colorscheme to rose-pine.
I generally use the codedark colorscheme. You can switch to that
with (#primeagen)

```
:lua ColorMyPencils("codedark")
```

This is the default colorscheme when first opening neovim with this config.

It's also worth mentioning that this config uses coc.nvim for lsp management,
which will not function if Node is not installed on the system.
