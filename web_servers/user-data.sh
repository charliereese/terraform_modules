#!/bin/bash

cat > index.html <<EOF
<h1>${server_text}</h1>
<p>DB port: ${db_port}</p>
EOF