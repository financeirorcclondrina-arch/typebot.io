#!/bin/sh

echo "🚀 Iniciando aplicação com SCOPE=$SCOPE"

cd apps/$SCOPE || exit 1

echo "📦 Gerando variáveis públicas..."

node -e "
const fs = require('fs');
const env = Object.keys(process.env)
  .filter(k => k.startsWith('NEXT_PUBLIC_'))
  .reduce((acc, k) => ({ ...acc, [k]: process.env[k] }), {});
fs.writeFileSync('/app/public/__ENV.js', 'window.__ENV=' + JSON.stringify(env));
"

echo "🗄️ Rodando Prisma..."

if [ -f "../../node_modules/.bin/prisma" ]; then
  ../../node_modules/.bin/prisma generate
else
  echo "⚠️ Prisma não encontrado"
fi

echo "🔥 Iniciando servidor..."

node server.js
