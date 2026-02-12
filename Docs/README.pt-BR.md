# SmartAsyncImage

Um `AsyncImage` para SwiftUI (iOS) mais inteligente e rápido, com cache em memória e em disco, cancelamento e concorrência do Swift 6.

[![CI](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml)
[![Coverage](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/branch/main/graph/badge.svg)](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage)
[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
![Bazel](https://img.shields.io/badge/Bazel-enabled-555?logo=bazel)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
![Commit activity](https://img.shields.io/github/commit-activity/y/gentle-giraffe-apps/SmartAsyncImage)
![Last commit](https://img.shields.io/github/last-commit/gentle-giraffe-apps/SmartAsyncImage)
[![DeepSource](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage.svg/?label=active+issues&show_trend=true)](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage/)

> 🌍 **Idioma** · [English](../README.md) · [Español](README.es.md) · Português (Brasil) · [日本語](README.ja.md) · [简体中文](README.zh-CN.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

## Funcionalidades
- API compatível com SwiftUI com um view model observável
- Gerenciamento inteligente de fases: `empty`, `loading`, `success(Image)`, `failure(Error)`
- Protocolo de cache em memória com implementações intercambiáveis
- Cache em disco para persistência entre execuções
- Concorrência do Swift (`async/await`) com cancelamento cooperativo
- Atualizações de estado seguras no MainActor

💬 **[Participe da discussão. Feedback e perguntas são bem-vindos](https://github.com/gentle-giraffe-apps/SmartAsyncImage/discussions)**

## Requisitos
- iOS 17+
- Swift 6.1+
- Swift Package Manager

## 📦 Instalação (Swift Package Manager)

### Via Xcode

1. Abra seu projeto no Xcode
2. Vá em **File → Add Packages...**
3. Insira a URL do repositório: `https://github.com/gentle-giraffe-apps/SmartAsyncImage.git`
4. Escolha uma regra de versão (ou `main` durante o desenvolvimento)
5. Adicione o produto **SmartAsyncImage** ao target do seu app

### Via `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/gentle-giraffe-apps/SmartAsyncImage.git", from: "1.0.0")
]
```

Em seguida, adicione `"SmartAsyncImage"` às `dependencies` do seu target.

## App de Demonstração

Um app de demonstração em SwiftUI está incluído neste repositório usando uma referência local ao pacote.

**Caminho:**
```
Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
```

### Como Executar
1. Clone o repositório:
   ```bash
   git clone https://github.com/gentle-giraffe-apps/SmartAsyncImage.git
   ```
2. Abra o projeto de demonstração:
   ```
   Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
   ```
3. Selecione um simulador com iOS 17+.
4. Compile e execute (⌘R).

O projeto já está configurado com uma referência local de Swift Package para `SmartAsyncImage` e deve executar sem configuração adicional.

## Uso

### Exemplo Rápido (SwiftUI)
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

Este projeto aplica controles de qualidade via CI e análise estática:

- **CI:** Todos os commits em `main` devem passar nas verificações do GitHub Actions
- **Análise estática:** O DeepSource é executado em cada commit em `main`.
  O badge indica o número atual de problemas pendentes de análise estática.
- **Cobertura de testes:** O Codecov reporta a cobertura de linhas para a branch `main`

<sub><strong>Captura do Codecov</strong></sub><br/>
<a href="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage">
  <img
    src="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/graphs/icicle.svg"
    height="80"
    alt="Captura de cobertura de código por arquivo e módulo (gráfico de árvore do Codecov)"
  />
</a>

Essas verificações têm como objetivo manter o sistema de design seguro para evoluir ao longo do tempo.

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

Partes da redação e do refinamento editorial neste repositório foram aceleradas utilizando modelos de linguagem grandes (incluindo ChatGPT, Claude e Gemini) sob design, validação e aprovação final humana direta. Todas as decisões técnicas, código e conclusões arquiteturais são de autoria e verificação do mantenedor do repositório.

---

## 🔐 Licença

Licença MIT
Livre para uso pessoal e comercial.

---

## 👤 Autor

Criado por **Jonathan Ritchey**
Gentle Giraffe Apps
Engenheiro Senior de iOS --- Swift | SwiftUI | Concurrency

![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fgentle-giraffe-apps%2FSmartAsyncImage)
