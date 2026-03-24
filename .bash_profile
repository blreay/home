HISTFILESIZE=1000000000
HISTSIZE=1000000
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

# 设置OpenClaw环境变量（即使在非交互式shell中也生效）
export OPENCLAW_HOME=/opt/openclaw
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# 加载.bashrc（仅在交互式shell中部分设置有效）
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

 export PATH="$HOME/.utoo-proxy:$PATH"
