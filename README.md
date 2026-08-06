# MeuCarro — Controle Automotivo Pessoal

App iOS nativo em **SwiftUI** para controle automotivo pessoal, com persistência local via **SwiftData**, mapas com **MapKit** e GPS com **Core Location**.

## Funcionalidades

- **Dashboard (Início)**: odômetro, consumo médio, gasto no mês, custo por km, distância no mês, último abastecimento e percursos recentes.
- **Combustível**:
  - Histórico completo de abastecimentos (agrupado por mês, com exclusão por deslize).
  - Consumo real (km/L) pelo método do **tanque cheio** (distância entre dois tanques cheios ÷ litros).
  - Comparador **gasolina vs etanol** com rendimento relativo ajustável.
- **Percursos**: gravação por GPS com distância, tempo, velocidade média e velocidade máxima, mapa ao vivo com a rota (MapKit) e gráfico de velocidade.
- **Performance**:
  - **0–100 km/h**: cronômetro automático via GPS (dispara ao acelerar e para ao atingir 100 km/h).
  - **Cold Start**: cronômetro manual de partida com histórico.
- **Relatórios**: gráficos (Swift Charts) de gasto mensal, custo por km, consumo real e distância percorrida por mês (3/6/12 meses).
- **Ajustes**: nome do veículo, odômetro, tipo de combustível, rendimento do etanol, **modo escuro/claro/sistema**, dados de exemplo e limpeza de dados.

## Requisitos

- macOS com **Xcode 16+**
- iOS **17.0+** (SwiftData, Swift Charts e nova API do MapKit)
- Para testar GPS/percursos/0–100: **iPhone físico** (o simulador não fornece atualizações de localização confiáveis em movimento)

## Como abrir

1. Copie a pasta `MeuCarro/` (ou o projeto inteiro) para um Mac.
2. Abra `MeuCarro.xcodeproj` no Xcode.
3. Em **Signing & Capabilities**, selecione sua equipe de desenvolvimento (o bundle id padrão é `com.meucarro.app`).
4. Selecione um dispositivo iPhone (iOS 17+) e rode.
5. Autorize a permissão de localização ao gravar um percurso ou ao armar o teste de 0–100.

## Estrutura

```
MeuCarro/
├── MeuCarroApp.swift            # Entry point + container SwiftData + tema
├── Models/                      # VehicleInfo, FuelFill, Trip, TripPoint, PerformanceRun
├── Services/                    # LocationService, TripRecorder, PerformanceService, FuelCalculator, Format
└── Views/
    ├── MainTabView.swift        # 5 abas
    ├── Dashboard/               # DashboardView
    ├── Fuel/                    # FuelView, AddFuelView, FuelComparatorView
    ├── Trips/                   # TripsView, AddTripView (recorder + mapa), TripDetailView
    ├── Performance/             # PerformanceView, ZeroToHundredView, ColdStartView
    ├── Reports/                 # ReportsView (gráficos)
    └── Settings/                # SettingsView
```

## Observações

- O consumo real usa o **método do tanque cheio**: marque "Tanque cheio" no abastecimento para alimentar o cálculo.
- O odômetro é atualizado automaticamente com os percursos registrados (e manualmente em Ajustes).
- A medição de 0–100 km/h é feita por GPS (~1 atualização/s) e é **aproximada** — não substitui equipamentos profissionais.
- Todos os dados ficam armazenados localmente no dispositivo (SwiftData).

## Gerar o .ipa pelo GitHub Actions

O build de iOS só roda em macOS, mas você não precisa de um Mac: o GitHub Actions usa
runners `macos-15` e entrega o `.ipa` assinado como artefato para download.

### 1. Publicar o projeto no GitHub

```bash
git init
git add .
git commit -m "MeuCarro"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/MeuCarro.git
git push -u origin main
```

### Não quer criar certificado?

Sem assinatura, o app **não instala em iPhone comum** (regra do iOS). Mas dá para
buildar mesmo assim e usar um destes caminhos:

| Opção | Custo | Como funciona |
| --- | --- | --- |
| **Build sem assinatura** (passo 2 abaixo) | grátis | Gera o `.ipa` sem assinatura. Só instala em iPhone com jailbreak. |
| **Serviço de assinatura** (ex.: Signulous, AppDB) | ~US$ 20/ano | Você envia o `.ipa` sem assinatura e eles assinam para o seu UDID. Instala direto no iPhone, sem certificado e sem conta de desenvolvedor. |
| **Apple ID grátis + Codemagic** | grátis | O Codemagic cria o certificado sozinho (via login com seu Apple ID), builda e instala no seu iPhone. Expira em 7 dias — reinstala a cada semana. |

**Resumo prático**: rode o **build sem assinatura** (passo 2), baixe o `.ipa`, e
envie para um serviço de assinatura ou use o Codemagic. Nenhum dos dois exige que
você crie certificado.

### 2. Rodar o build

- Abra **Actions → Build IPA → Run workflow**.
- Com **Signing = `none`** (padrão): gera o **MeuCarro-Release-none.ipa** sem
  assinatura (para jailbreak ou serviços de assinatura). Não precisa de secrets.
- Com **Signing = `manual`**: gera o `.ipa` assinado (veja o passo 3 abaixo).
- Baixe o artefato e instale no iPhone com Apple Configurator, iMazing ou Sideloadly.
- Também dispara automaticamente ao criar uma tag `v*`.

### 3. (Opcional) Assinatura manual — certificado e perfil

O iOS exige assinatura de código para instalar em iPhone comum. Você precisa de
**uma conta Apple Developer** (paga, ~R$ 400/ano) ou de um Apple ID gratuito
(certificado expira em 7 dias).

**Sem Mac? Sem problema.** Com a conta paga, tudo é feito pelo navegador + OpenSSL:

```powershell
winget install OpenSSL.Light          # no Windows (ou use Git for Windows)
cd MeuCarro
.\scripts\export-keys.ps1             # passo 1: gera key.pem + certificate.csr
```

1. Abra `developer.apple.com/account/resources/certificates`, crie o certificado
   (Apple Development para instalar no iPhone) e envie o `certificate.csr`.
   Baixe o `.cer` e salve como `cert.cer`.
2. Registre o **UDID do seu iPhone** sem Mac: abra `https://udid.io` no Safari do
   iPhone (ou use o app Apple Developer no iPhone → Devices).
3. Crie o profile em `developer.apple.com/account/resources/profiles`
   (Development/Ad Hoc) e baixe o `.mobileprovision`.
4. Rode o script de novo — ele converte tudo em `.p12` e imprime os secrets prontos:

```powershell
.\scripts\export-keys.ps1 -CertCer cert.cer -ProvisioningProfile MeuCarro.mobileprovision -P12Password minhasenha
```

Se você tiver acesso a qualquer Mac, o `scripts/export-keys.sh` faz o mesmo em uma etapa.

### 4. Configurar os secrets no GitHub (apenas assinatura manual)

No repositório: **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Valor |
| --- | --- |
| `IOS_CERTIFICATE` | base64 do `certificate.p12` (impresso pelo script) |
| `IOS_CERTIFICATE_PASSWORD` | senha usada no P12_PASSWORD |
| `IOS_PROVISIONING_PROFILE` | base64 do `.mobileprovision` (impresso pelo script) |
| `IOS_SIGNING_IDENTITY` | ex.: `Apple Development: Seu Nome (TEAMID)` |
| `IOS_TEAM_ID` | ID do time (impresso pelo script) |
| `IOS_PROVISIONING_PROFILE_NAME` | nome do perfil (impresso pelo script) |

> **Importante**: o certificado/ perfil expiram (1 ano na conta paga, 7 dias na gratuita).
> Quando expirar, refaça o passo 3 e atualize os secrets. Os arquivos de chave nunca devem
> ser enviados ao repositório (estão no `.gitignore`).
