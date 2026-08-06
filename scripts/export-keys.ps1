<#
export-keys.ps1 - Gere certificado e perfil de provisionamento SEM Mac (Windows + OpenSSL)

Requisitos:
  - Conta Apple Developer PAGA (developer.apple.com)
  - OpenSSL instalado:  winget install OpenSSL.Light   (ou Git for Windows)

Passos:
  1) Rode:  .\scripts\export-keys.ps1
     -> gera key.pem + certificate.csr
  2) No navegador: developer.apple.com > Certificates
     - crie o certificado e envie o .csr
       * "Apple Development"  -> instalar no iPhone (export method: development)
       * "Apple Distribution" -> Ad Hoc / App Store (export method: ad-hoc)
     - baixe o .cer e salve como cert.cer
  3) Registre o UDID do iPhone:
     - abra https://udid.io no Safari do iPhone (ou o app Apple Developer > Devices)
     - crie o profile em developer.apple.com > Profiles e baixe o .mobileprovision
  4) Rode de novo apontando os arquivos:
     .\scripts\export-keys.ps1 -CertCer cert.cer -ProvisioningProfile MeuCarro.mobileprovision -P12Password minhasenha
  5) Configure os 6 valores impressos como secrets no GitHub
     (Settings > Secrets and variables > Actions)
#>

param(
    [string]$CertCer = "cert.cer",
    [string]$CertP12 = "certificate.p12",
    [string]$KeyOut = "key.pem",
    [string]$CsrOut = "certificate.csr",
    [string]$ProvisioningProfile = "MeuCarro.mobileprovision",
    [string]$P12Password = "minhasenha123",
    [string]$CommonName = "MeuCarro CI",
    [string]$WWDRCer = ""
)

$ErrorActionPreference = "Stop"

function Find-OpenSsl {
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $gitPath = "$env:ProgramFiles\Git\usr\bin\openssl.exe"
    if (Test-Path $gitPath) { return $gitPath }
    throw "OpenSSL nao encontrado. Instale com: winget install OpenSSL.Light  (ou use o Git for Windows)"
}

$openssl = Find-OpenSsl

# ---------- Passo 1: gerar chave privada + CSR ----------
if (-not (Test-Path $CertCer)) {
    if (-not (Test-Path $KeyOut) -or -not (Test-Path $CsrOut)) {
        Write-Host "== Gerando chave privada e CSR =="
        & $openssl req -new -newkey rsa:2048 -nodes -keyout $KeyOut -out $CsrOut -subj "/CN=$CommonName"
        Write-Host "Chave: $KeyOut"
        Write-Host "CSR : $CsrOut"
    }
    Write-Host ""
    Write-Host "Agora no navegador:"
    Write-Host "  1. Acesse developer.apple.com/account/resources/certificates"
    Write-Host "  2. Crie um certificado (Apple Development ou Apple Distribution) e envie o $CsrOut"
    Write-Host "  3. Baixe o .cer e salve como: $CertCer"
    Write-Host "  4. Depois rode: .\scripts\export-keys.ps1 -ProvisioningProfile caminho\para\MeuCarro.mobileprovision"
    exit 0
}

# ---------- Passo 2: converter .cer + key em .p12 ----------
if (-not (Test-Path $KeyOut)) {
    throw "Arquivo $KeyOut nao encontrado. Exclua o $CertCer e gere o CSR de novo."
}

Write-Host "== Convertendo certificado + chave em .p12 =="
if ($WWDRCer) {
    & $openssl pkcs12 -export -out $CertP12 -inkey $KeyOut -in $CertCer -certfile $WWDRCer -password "pass:$P12Password"
} else {
    & $openssl pkcs12 -export -out $CertP12 -inkey $KeyOut -in $CertCer -password "pass:$P12Password"
}
if ($LASTEXITCODE -ne 0) { throw "Falha ao converter o .p12" }

# Identidade de assinatura = CN do certificado
$subject = (& $openssl x509 -in $CertCer -noout -subject) -join " "
$identity = "?"
if ($subject -match 'CN\s*=\s*([^,/]+)') { $identity = $matches[1].Trim() }

# ---------- Passo 3: perfil de provisionamento ----------
if (-not (Test-Path $ProvisioningProfile)) {
    Write-Host ""
    Write-Host "Perfil nao encontrado: $ProvisioningProfile"
    Write-Host "  - Registre o UDID do iPhone: abra https://udid.io no Safari do iPhone"
    Write-Host "    (ou use o app Apple Developer no iPhone > Devices)"
    Write-Host "  - Crie o profile em developer.apple.com/account/resources/profiles"
    Write-Host "  - Baixe o .mobileprovision e rode o script de novo com o caminho."
    exit 0
}

$profilePlist = (& $openssl smime -inform der -verify -noverify -binary -in $ProvisioningProfile) -join "`n"
$profileName = "?"
if ($profilePlist -match '<key>Name</key>\s*<string>([^<]+)</string>') { $profileName = $matches[1].Trim() }
$teamId = "?"
if ($profilePlist -match '<key>TeamIdentifier</key>\s*<array>\s*<string>([^<]+)</string>') { $teamId = $matches[1].Trim() }
$appId = "?"
if ($profilePlist -match '<key>application-identifier</key>\s*<string>([^<]+)</string>') { $appId = $matches[1].Trim() }
$expiry = "?"
if ($profilePlist -match '<key>ExpirationDate</key>\s*<date>([^<]+)</date>') { $expiry = $matches[1].Trim() }

$p12B64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $CertP12).Path))
$profileB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $ProvisioningProfile).Path))

Write-Host ""
Write-Host "== Dados do perfil =="
Write-Host "Perfil : $profileName"
Write-Host "Team   : $teamId"
Write-Host "App id : $appId"
Write-Host "Expira : $expiry"
Write-Host ""
Write-Host "== Secrets para o GitHub (Settings > Secrets and variables > Actions) =="
Write-Host ""
Write-Host "IOS_CERTIFICATE=$p12B64"
Write-Host ""
Write-Host "IOS_CERTIFICATE_PASSWORD=$P12Password"
Write-Host ""
Write-Host "IOS_PROVISIONING_PROFILE=$profileB64"
Write-Host ""
Write-Host "IOS_SIGNING_IDENTITY=$identity"
Write-Host ""
Write-Host "IOS_TEAM_ID=$teamId"
Write-Host ""
Write-Host "IOS_PROVISIONING_PROFILE_NAME=$profileName"
Write-Host ""
Write-Host "== Atencao =="
Write-Host "- Certificados e perfis expiram (1 ano na conta paga)."
Write-Host "- Nunca envie key.pem / certificate.p12 / *.mobileprovision para o repositorio."
