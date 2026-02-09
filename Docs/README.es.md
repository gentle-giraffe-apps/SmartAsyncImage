# SmartAsyncImage

Un `AsyncImage` para SwiftUI (iOS) mas inteligente y rapido, con cache en memoria y en disco, cancelacion y concurrencia de Swift 6.

[![CI](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/gentle-giraffe-apps/SmartAsyncImage/actions/workflows/ci.yml)
[![Coverage](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/branch/main/graph/badge.svg)](https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage)
[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
![Bazel](https://img.shields.io/badge/Bazel-enabled-555?logo=bazel)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue)](https://developer.apple.com/ios/)
![Commit activity](https://img.shields.io/github/commit-activity/y/gentle-giraffe-apps/SmartAsyncImage)
![Last commit](https://img.shields.io/github/last-commit/gentle-giraffe-apps/SmartAsyncImage)
[![DeepSource](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage.svg/?label=active+issues&show_trend=true)](https://app.deepsource.com/gh/gentle-giraffe-apps/SmartAsyncImage/)

> **Idioma** · [English](../README.md) · Español · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md)

## Caracteristicas
- API compatible con SwiftUI con un view model observable
- Manejo inteligente de fases: `empty`, `loading`, `success(Image)`, `failure(Error)`
- Protocolo de cache en memoria con implementaciones intercambiables
- Cache en disco para persistencia entre ejecuciones
- Concurrencia de Swift (`async/await`) con cancelacion cooperativa
- Actualizaciones de estado seguras en MainActor

💬 **[Participa en la discusion. Comentarios y preguntas son bienvenidos](https://github.com/gentle-giraffe-apps/SmartAsyncImage/discussions)**

## Requisitos
- iOS 17+
- Swift 6.1+
- Swift Package Manager

## 📦 Instalacion (Swift Package Manager)

### Via Xcode

1. Abre tu proyecto en Xcode
2. Ve a **File → Add Packages...**
3. Ingresa la URL del repositorio: `https://github.com/gentle-giraffe-apps/SmartAsyncImage.git`
4. Elige una regla de version (o `main` durante el desarrollo)
5. Agrega el producto **SmartAsyncImage** a tu target de la app

### Via `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/gentle-giraffe-apps/SmartAsyncImage.git", from: "1.0.0")
]
```

Luego agrega `"SmartAsyncImage"` a las `dependencies` de tu target.

## App de Demostracion

Se incluye una app de demostracion en SwiftUI en este repositorio usando una referencia local al paquete.

**Ruta:**
```
Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
```

### Como Ejecutar
1. Clona el repositorio:
   ```bash
   git clone https://github.com/gentle-giraffe-apps/SmartAsyncImage.git
   ```
2. Abre el proyecto de demostracion:
   ```
   Demo/SmartAsyncImageDemo/SmartAsyncImageDemo.xcodeproj
   ```
3. Selecciona un simulador con iOS 17+.
4. Compila y ejecuta (⌘R).

El proyecto esta preconfigurado con una referencia local de Swift Package a `SmartAsyncImage` y deberia ejecutarse sin configuracion adicional.

## Uso

### Ejemplo Rapido (SwiftUI)
```swift
import SwiftUI
import SmartAsyncImage

struct MinimalRemoteImageView: View {
    let imageURL = URL(string: "https://picsum.photos/300")

    var body: some View {

        // reemplaza: AsyncImage(url: imageURL) { phase in
        // ------------------------------------------------
        // con:

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

## Calidad y Herramientas

Este proyecto aplica controles de calidad mediante CI y analisis estatico:

- **CI:** Todos los commits a `main` deben pasar las verificaciones de GitHub Actions
- **Analisis estatico:** DeepSource se ejecuta en cada commit a `main`.
  La insignia indica el numero actual de problemas pendientes de analisis estatico.
- **Cobertura de tests:** Codecov reporta la cobertura de lineas para la rama `main`

<sub><strong>Captura de Codecov</strong></sub><br/>
<a href="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage">
  <img
    src="https://codecov.io/gh/gentle-giraffe-apps/SmartAsyncImage/graphs/icicle.svg"
    height="80"
    alt="Captura de cobertura de codigo por archivo y modulo (grafico de arbol de Codecov)"
  />
</a>

Estas verificaciones tienen como objetivo mantener el sistema de diseno seguro para evolucionar con el tiempo.

---

## Arquitectura

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

## 🤖 Nota sobre Herramientas

Partes de la redaccion y el refinamiento editorial en este repositorio fueron aceleradas utilizando modelos de lenguaje grandes (incluyendo ChatGPT, Claude y Gemini) bajo diseno, validacion y aprobacion final humana directa. Todas las decisiones tecnicas, el codigo y las conclusiones arquitectonicas son de autoria y verificacion del mantenedor del repositorio.

---

## 🔐 Licencia

Licencia MIT
Libre para uso personal y comercial.

---

## 👤 Autor

Creado por **Jonathan Ritchey**
Gentle Giraffe Apps
Ingeniero Senior de iOS --- Swift | SwiftUI | Concurrency

![Visitors](https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fgentle-giraffe-apps%2FSmartAsyncImage)
