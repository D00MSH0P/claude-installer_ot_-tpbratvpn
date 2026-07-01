cat > install-claude.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CFG_DIR="$HOME/.claude"
CFG_FILE="$CFG_DIR/settings.json"

green(){ echo -e "\033[32m$*\033[0m"; }
yellow(){ echo -e "\033[33m$*\033[0m"; }
red(){ echo -e "\033[31m$*\033[0m"; }

need_root(){
  [ "$(id -u)" -eq 0 ] || { red "Запусти от root"; exit 1; }
}

install_node(){
  if command -v node >/dev/null 2>&1 && [ "$(node -v | sed 's/v//' | cut -d. -f1)" -ge 18 ]; then
    green "Node OK: $(node -v)"
    return
  fi
  yellow "Ставлю Node.js 20..."
  apt update
  apt install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
}

write_config(){
  read -rp "Base URL [https://modelhub.my]: " BASE_URL
  BASE_URL="${BASE_URL:-https://modelhub.my}"
  BASE_URL="${BASE_URL%/}"

  read -rsp "API key: " API_KEY
  echo
  [ -n "$API_KEY" ] || { red "Пустой ключ"; exit 1; }

  read -rp "Использовать proxy? [y/N]: " USE_PROXY

  mkdir -p "$CFG_DIR"
  chmod 700 "$CFG_DIR"

  if [[ "$USE_PROXY" =~ ^[YyДд]$ ]]; then
    read -rp "Proxy URL, пример http://1.2.3.4:8080 или http://login:pass@ip:port: " PROXY_URL

    cat > "$CFG_FILE" <<JSON
{
  "env": {
    "ANTHROPIC_BASE_URL": "$BASE_URL",
    "ANTHROPIC_API_KEY": "$API_KEY",
    "HTTP_PROXY": "$PROXY_URL",
    "HTTPS_PROXY": "$PROXY_URL",
    "ALL_PROXY": "$PROXY_URL"
  }
}
JSON
  else
    cat > "$CFG_FILE" <<JSON
{
  "env": {
    "ANTHROPIC_BASE_URL": "$BASE_URL",
    "ANTHROPIC_API_KEY": "$API_KEY"
  }
}
JSON
  fi

  chmod 600 "$CFG_FILE"
  green "Конфиг записан: $CFG_FILE"
}

install_claude(){
  install_node
  yellow "Ставлю Claude Code..."
  npm install -g @anthropic-ai/claude-code
  write_config
  green "Готово. Запуск: claude"
}

update_claude(){
  npm install -g @anthropic-ai/claude-code@latest
  green "Обновлено."
}

remove_claude(){
  npm uninstall -g @anthropic-ai/claude-code || true
  read -rp "Удалить конфиг ~/.claude/settings.json? [y/N]: " DEL
  [[ "$DEL" =~ ^[YyДд]$ ]] && rm -f "$CFG_FILE"
  green "Удалено."
}

menu(){
  clear
  echo "================================================="
  echo "🚀1шедевроустановщик клода от @tpbratvpn🚀"
  echo "================================================="
  echo
  echo "1) Установить / Переустановить"
  echo "2) Обновить Claude"
  echo "3) Поменять API / Proxy"
  echo "4) Удалить нахуй Claude"
  echo "5) Показать путь конфига"
  echo
  echo "0) выйти"
  echo
  read -rp "👉 Выберите пункт:" CHOICE

  case "$CHOICE" in
    1) install_claude ;;
    2) update_claude ;;
    3) write_config ;;
    4) remove_claude ;;
    5) echo "$CFG_FILE" ;;
    0) exit 0 ;;
    *) red "Неверный выбор" ;;
  esac
}

need_root
menu
EOF

chmod +x install-claude.sh
bash install-claude.sh