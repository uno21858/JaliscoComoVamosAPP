#!/bin/sh
# Despliega supabase/jcv-asistente a CCL DEV (verify_jwt queda activo).
# El CLI busca supabase/functions/<nombre>; el repo usa supabase/<nombre> como CCL,
# así que se copia a una carpeta temporal. Requiere `supabase login`.
set -e
repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/supabase/functions/jcv-asistente"
cp "$repo/supabase/jcv-asistente/index.ts" "$tmp/supabase/functions/jcv-asistente/"
cd "$tmp" && supabase functions deploy jcv-asistente --project-ref aywtzsgnmdjhsufnxmfk --use-api
