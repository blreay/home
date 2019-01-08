#!/bin/bash

pid=$1

[[ -z $pid ]] && echo "Usage: ${0##*/} <pid>" && exit 1

ruby -wn - /proc/$pid/status <<'EOF'
if $_.match(/Sig(Pnd|Blk|Ign|Cgt):\s([0-9a-f]{16})/) == nil
  next
end
field = $1
mask = $2.to_i(16)
names = []
Signal.list().each_pair() {
  |name, number|
  if number == 0
    next
  end
  if (mask & (1 << (number - 1))) == 0
    next
  end
  names << name
}
puts("Sig#{field}: #{names.join(" | ")}")
EOF

