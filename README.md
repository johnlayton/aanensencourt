# AanensenCourt

### Setup oh-my-zsh

#### Install aanensencourt plugin
```zsh
pushd $ZSH/custom/plugins && \
  git clone git@github.com:johnlayton/aanensencourt.git aanensencourt && \
  popd || echo "I'm broken"
```
```zsh
plugins=(... aanensencourt)
```

### Setup other

```zsh
pushd $HOME && \
  git clone git@github.com:johnlayton/aanensencourt.git .aanensencourt && \
  popd || echo "I'm broken"
```

```zsh
source ~/.aanensencourt/aanensencourt.plugin.zsh
```
