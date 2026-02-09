# SmartAsyncImage

Um `AsyncImage` para SwiftUI (iOS) mais inteligente e rapido, com cache em memoria e em disco, cancelamento e concorrencia do Swift 6.

[![CI](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml)
[![Coverage](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/branch/main/graph/badge.svg)](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage)
[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
![Bazel](https://img.shields.io/badge/Bazel-enabled-555?logo=bazel)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
![Commit activity](https://img.shields.io/github/commit-activity/y/gentle-giraffe-apps/SmartAsyncImage)
![Last commit](https://img.shields.io/github/last-commit/gentle-giraffe-apps/SmartAsyncImage)
[![DeepSource](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage.svg/?label=active+issues&show_trend=true)](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage/)

> **Idioma** · [English](../README.md) · [Español](README.es.md) · Português (Brasil) · [日本語](README.ja.md)

## Funcionalidades
- API compativel com SwiftUI com um view model observavel
- Gerenciamento inteligente de fases: `empty`, `loading`, `success(Image)`, `failure(Error)`
- Protocolo de cache em memoria com implementacoes intercambiaveis
- Cache em disco para persistencia entre execucoes
- Concorrencia do Swift (`async/await`) com cancelamento cooperativo
- Atualizacoes de estado seguras no MainActor

💬 **[Participe da discussao. Feedback e perguntas sao bem-vindos](https://github.com/gentle-giraffe-apps/SmartAsyncImage/discussions)**

## Requisitos
- iOS 17+
- Swift 6.1+
- Swift Package Manager

## 📦 Instalacao (Swift Package Manager)

### Via Xcode

1. Abra seu projeto no Xcode
2. Va em **File → Add Packages...**
3. Insira a URL do repositorio: `https://github.com/gentle-giraffe-apps/SmartAsyncImage.git`
4. Escolha uma regra de versao (ou `main` durante o desenvolvimento)
5. Adicione o produto **SmartAsyncImage** ao target do seu app

### Via `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/gentle-giraffe-apps/SmartAsyncImage.git", from: "1.0.0")
]
```

Em seguida, adicione `"SmartAsyncImage"` as `dependencies` do seu target.

## App de Demonstracao

Um app de demonstracao em SwiftUI esta incluido neste repositorio usando uma referencia local ao pacote.

**Caminho:**
```
Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
```

### Como Executar
1. Clone o repositorio:
   ```bash
   git clone https://github.com/gentle-giraffe-apps/SmartAsyncImage.git
   ```
2. Abra o projeto de demonstracao:
   ```
   Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
   ```
3. Selecione um simulador com iOS 17+.
4. Compile e execute (⌘R).

O projeto ja esta configurado com uma referencia local de Swift Package para `SmartAsyncImage` e deve executar sem configuracao adicional.

## Uso

### Exemplo Rapido (SwiftUI)
```swift
import SwiftUI
import SmartAsyncImage

struct MinimalRemoteImageView: View {
    let imageURL = URL(string: "https://picsum.photos/300")

    var body: some View {

        // substitua: AsyncImage(url: imageURL) { phase in
        // ------------------------------------------------
        // por:

        SmartAsyncImage(url: imageURL) { phase in

        // ------------------------------------------------

            switch phase {
            case .empty, .loading:
                ProgressView()
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo")
            }
        }
        .frame(width: 150, height: 150)
    }
}
```

## Qualidade e Ferramentas

Este projeto aplica controles de qualidade via CI e analise estatica:

- **CI:** Todos os commits em `main` devem passar nas verificacoes do GitHub Actions
- **Analise estatica:** O DeepSource e executado em cada commit em `main`.
  O badge indica o numero atual de problemas pendentes de analise estatica.
- **Cobertura de testes:** O Codecov reporta a cobertura de linhas para a branch `main`

<sub><strong>Captura do Codecov</strong></sub><br/>
<a href="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage">
  <img
    src="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/graphs/icicle.svg"
    height="80"
    alt="Captura de cobertura de codigo por arquivo e modulo (grafico de arvore do Codecov)"
  />
</a>

Essas verificacoes tem como objetivo manter o sistema de design seguro para evoluir ao longo do tempo.

---

## Arquitetura

```mermaid
flowchart TD
    SAI["SmartAsyncImage<br/>(SwiftUI View)"] --> VM["SmartAsyncImage<br/>ViewModel"]
    VM --> Phase["SmartAsyncImage<br/>Phase"]
    VM --> MemProto["SmartAsyncImageMemory<br/>CacheProtocol"]
    MemProto --> Mem["SmartAsyncImage<br/>MemoryCache<br/>(actor)"]
    Mem --> Disk["SmartAsyncImage<br/>DiskCache"]
    Disk --> Encoder["SmartAsyncImage<br/>Encoder"]
    Mem --> URLSession[["URLSession"]]
```

---

## 🤖 Nota sobre Ferramentas

Partes da redacao e do refinamento editorial neste repositorio foram aceleradas utilizando modelos de linguagem grandes (incluindo ChatGPT, Claude e Gemini) sob design, validacao e aprovacao final humana direta. Todas as decisoes tecnicas, codigo e conclusoes arquiteturais sao de autoria e verificacao do mantenedor do repositorio.

---

## 🔐 Licenca

Licenca MIT
Livre para uso pessoal e comercial.

---

## 👤 Autor

Criado por **Jonathan Ritchey**
Gentle Giraffe Apps
Engenheiro Senior de iOS --- Swift | SwiftUI | Concurrency

![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fgentle-giraffe-apps%2FSmartAsyncImage)
