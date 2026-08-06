#!/bin/bash
# export-keys.sh
#
# Exporta a identidade de assinatura (.p12) e o perfil de provisionamento (.mobileprovision)
# de um Mac e imprime os valores prontos para configurar os secrets do GitHub Actions.
#
# Uso:
#   1. No Mac (Xcode logado com sua conta de desenvolvedor), liste as identidades:
#        ./scripts/export-keys.sh
#   2. Exporte a identidade escolhida:
#        P12_PASSWORD="senha-temporaria" ./scripts/export-keys.sh "Apple Development: Seu Nome (TEAMID)" ~/path/para/MeuCarro.mobileprovision
#   3. Copie os valores impressos e configure como secrets no repositório (Settings > Secrets).
#
# Requisitos:
#   - Conta Apple Developer (paga) OU conta gratuita (certificados gratuitos expiram em 7 dias).
#   - Um certificado de desenvolvimento (p12) criado no Keychain de um Mac.
#   - Um perfil de provisionamento (development/ad-hoc) contendo o bundle id com.meucarro.app
#     e os UDIDs dos iPhones onde o app será instalado.

set -euo pipefail

if [ -z "$1" ] || [ "$1" = "--list" ]; then
  echo "== Identidades de assinatura disponíveis no Keychain =="
  security find-identity -v -p codesigning
  echo ""
  echo "Para exportar, use:"
  echo "  P12_PASSWORD=\"sua-senha\" $0 \"Nome da Identidade\" caminho/para/perfil.mobileprovision"
  exit 0
fi

IDENTITY="$1"
PROFILE_PATH="$2"
P12_PASSWORD="${P12_PASSWORD:?Defina P12_PASSWORD (senha temporária do .p12)}"
P12_OUT="${P12_OUT:-certificate.p12}"

# 1. Exporta a identidade (certificado + chave privada) como .p12
security export \
  -k ~/Library/Keychains/login.keychain-db \
  -t identity \
  -f pkcs12 \
  -P "$P12_PASSWORD" \
  -o "$P12_OUT" \
  "$IDENTITY"
echo "P12 exportado: $P12_OUT"

# 2. Extrai informações do perfil de provisionamento
PROFILE_INFO="/tmp/meucarro_profile.plist"
security cms -D -i "$PROFILE_PATH" > "$PROFILE_INFO"
PROFILE_NAME="$(plutil -extract Name raw -o - "$PROFILE_INFO")"
PROFILE_UUID="$(plutil -extract UUID raw -o - "$PROFILE_INFO")"
TEAM_ID="$(plutil -extract TeamIdentifier.0 raw -o - "$PROFILE_INFO")"
EXPIRY="$(plutil -extract ExpirationDate raw -o - "$PROFILE_INFO")"
BUNDLE_ID="$(plutil -extract Entitlements.application-identifier raw -o - "$PROFILE_INFO" | sed 's/^[A-Z0-9]*\.//')"

echo ""
echo "== Dados do perfil =="
echo "Perfil  : $PROFILE_NAME"
echo "UUID    : $PROFILE_UUID"
echo "Team    : $TEAM_ID"
echo "Bundle  : $BUNDLE_ID"
echo "Expira  : $EXPIRY"
echo ""

# 3. Imprime os valores prontos para os secrets do GitHub
echo "== Secrets para configurar no GitHub (Settings > Secrets and variables > Actions) =="
echo ""
echo "IOS_CERTIFICATE=$(base64 -i "$P12_OUT" | tr -d '\n')"
echo ""
echo "IOS_CERTIFICATE_PASSWORD=$P12_PASSWORD"
echo ""
echo "IOS_PROVISIONING_PROFILE=$(base64 -i "$PROFILE_PATH" | tr -d '\n')"
echo ""
echo "IOS_SIGNING_IDENTITY=$IDENTITY"
echo ""
echo "IOS_TEAM_ID=$TEAM_ID"
echo ""
echo "IOS_PROVISIONING_PROFILE_NAME=$PROFILE_NAME"
echo ""
echo "== Avisos =="
echo "- O secret IOS_CERTIFICATE expira quando o certificado expirar (1 ano pago / 7 dias grátis)."
echo "- Mantenha o $P12_OUT e o perfil em lugar seguro; nunca os envie para o repositório."
