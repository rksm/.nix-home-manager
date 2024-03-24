A very lightweight, one-file nix home-manager setup.

Requires curl & git.

Install with

```sh
# install nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# install home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# clone & apply config
mkdir -p ~/.config && cd ~/.config
git clone https://github.com/rksm/.nix-home-manager home-manager
home-manager switch
```
