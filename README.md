# Servidor Web en Go con Docker Multi-stage 🚀

Este repositorio es un ejemplo práctico de cómo construir imágenes de Docker ultra eficientes utilizando **Multi-stage builds** (Construcciones Multi-etapa) con el lenguaje de programación **Go**.

El objetivo principal es demostrar cómo reducir drásticamente el tamaño de la imagen final de producción, manteniendo todas las herramientas de desarrollo y compilación aisladas en una etapa intermedia que luego se descarta.

## 📌 ¿Por qué usar Multi-stage con Go?

Go es un lenguaje compilado que genera un **único archivo binario independiente**. Esto significa que:
1. No necesitas el entorno de ejecución (runtime) ni el kit de desarrollo (compilador de Go, herramientas de red, etc.) en tu servidor de producción.
2. Con **Multi-stage**, utilizamos una imagen pesada y completa para construir el binario (Etapa de Compilación) y posteriormente lo transferimos a una imagen ultra ligera (como Alpine o Scratch) de solo unos pocos megabytes (Etapa Final).

---

## 🛠️ Estructura del Código Go

El servidor web está desarrollado utilizando únicamente la biblioteca estándar de Go, lo que garantiza máxima velocidad y cero dependencias externas.

### Explicación del Código (`main.go`)

* **`package main`**: Le dice al compilador de Go que este archivo es el punto de entrada de la aplicación. Todo programa ejecutable en Go requiere pertenecer al paquete `main`.
* **`import (...)`**: Importa dos librerías nativas esenciales:
    * `fmt`: Sirve para dar formato a textos e imprimirlos (en la terminal o en la respuesta web).
    * `net/http`: Contiene todas las herramientas para crear servidores y clientes HTTP de forma nativa.
* **La función `handler`**: Es el "recepcionista" de las peticiones. Se ejecuta cada vez que alguien visita el servidor y recibe dos argumentos:
    * `w http.ResponseWriter`: El canal para responder al usuario. Lo que escribas aquí se renderizará en el navegador.
    * `r *http.Request`: Contiene toda la información de la petición del usuario (IP, navegador, datos enviados, etc.).
    * `fmt.Fprintf(w, ...)`**: Inyecta el texto directamente en el canal de respuesta (`w`) para mostrarlo en la pantalla del usuario.
* **La función `main`**: El punto de partida de la magia:
    * `http.HandleFunc("/", handler)`: Registra la ruta raíz (`/`) y la asocia con nuestro recepcionista (`handler`).
    * `fmt.Println(...)`: Muestra un mensaje en la terminal indicando que el servidor ha iniciado con éxito.
    * `http.ListenAndServe(":8080", nil)`: Enciende el servidor y lo deja escuchando de forma permanente en el puerto `8080`.

---

## 🐋 ¿Cómo funciona el Dockerfile Multi-stage?

El archivo `Dockerfile` de este proyecto se estructura utilizando dos instrucciones `FROM`, dividiendo el ciclo de vida en dos fases bien definidas:

### 1. Etapa de Construcción (`FROM golang... AS build`)
* Descarga un entorno completo de Go (cuyo peso puede superar los 800 MB).
* Copia el código fuente dentro del contenedor.
* Compila el archivo ejecutable (`mi-app-go`).
* Una vez generado el binario, esta imagen pesada ya no es necesaria y se desecha.

### 2. Etapa Final (`FROM alpine...` o `FROM scratch`)
* Comienza desde cero con una imagen limpia y diminuta (por ejemplo, Alpine Linux ~5 MB).
* **La línea mágica**: `COPY --from=build` entra a la etapa anterior, extrae únicamente el binario compilado y lo copia a la nueva imagen.
* Todo el compilador de Go y las herramientas de desarrollo se descartan por completo.

---

## 🛡️ El Enfoque DevSecOps: Seguridad desde el Diseño (*Shift Left*)

En la cultura **DevSecOps**, la seguridad no es una fase final de revisión, sino una responsabilidad compartida que se integra desde las primeras líneas del código y la configuración. Este ejemplo de **Multi-stage build** es un pilar fundamental de DevSecOps por tres razones críticas:

### 1. Reducción Radical de la Superficie de Ataque
Las imágenes de desarrollo (como `golang:alpine` o `golang:latest`) contienen herramientas como administradores de paquetes (`apk`, `apt`), compiladores, shells (`bash`, `sh`) y utilidades de red (`curl`, `wget`). Si un atacante logra comprometer tu aplicación en producción, usará estas herramientas empaquetadas para escalar privilegios o moverse lateralmente por tu red. 
* Al usar **Multi-stage**, la imagen final queda completamente "desnuda", conteniendo **únicamente** el binario ejecutable. No hay herramientas que un atacante pueda explotar.

### 2. Mitigación Automática de Vulnerabilidades (CVEs)
Las herramientas de escaneo de contenedores (como *Trivy*, *Grype* o *Snyk*) analizan los paquetes instalados en el sistema operativo del contenedor.
* Una imagen completa de Go puede arrastrar cientos de vulnerabilidades teóricas debido a su sistema base pesado.
* Al pasar el artefacto a una etapa basada en `alpine` o `scratch`, el número de dependencias del sistema operativo cae a casi cero, **eliminando automáticamente el 95% de las vulnerabilidades (CVEs)** del reporte de seguridad.

### 3. Automatización en el Pipeline de CI/CD
En un flujo DevSecOps real, este Dockerfile permite separar los pasos de validación. Podríamos añadir una etapa intermedia de pruebas estáticas de seguridad (SAST) o escaneo de dependencias, asegurando que el binario solo se compile si pasa los umbrales de seguridad establecidos. 

## 🧠 Conceptos Clave para Recordar

* **Etapas (`FROM ... AS nombre`)**: Pasos independientes dentro del Dockerfile. Cada nuevo `FROM` borra la memoria del contenedor de compilación anterior y arranca desde un entorno limpio.
* **Artefacto**: El producto final compilado (en este caso, el binario de Go). Es lo único que nos interesa conservar para producción.
* **`COPY --from`**: El puente entre etapas. Permite extraer archivos/artefactos de una fase previa y moverlos a la etapa actual.
* **Inmutabilidad de Capas (Layers)**: Cada instrucción en un Dockerfile tradicional (`RUN`, `COPY`) añade una capa de solo lectura. Aunque borres archivos temporales al final del script, siguen ocupando espacio en las capas ocultas. Multi-stage soluciona esto porque la Etapa Final nace sin el historial de capas de la fase de compilación.
* **Compilación Estática vs Dinámica**: Lenguajes como Go, Rust o C++ permiten compilación estática (todo se empaqueta en el binario), siendo ideales para usar incluso con `FROM scratch`. Los lenguajes interpretados (Python, Node.js, PHP) requieren entornos dinámicos; en ellos, el Multi-stage sirve para instalar dependencias pesadas en la Etapa 1 y mover solo los módulos limpios a una Etapa 2 basada en versiones *slim* o *alpine*.

---

## 📈 Beneficios y Eficiencia

| Métrica | Beneficio |
| :--- | :--- |
| **Almacenamiento** | Reduces el peso de tus imágenes de producción hasta en un **95%**. |
| **Eficiencia de Red** | Subir y bajar 12 MB en tu pipeline de CI/CD o servidores toma milisegundos en comparación con mover ~1 GB. |
| **Memoria y Arranque** | Al ser contenedores tan pequeños, el motor de Docker los enciende y los replica casi instantáneamente. |
| **Seguridad** | Al eliminar compiladores, gestores de paquetes y shells de la imagen final, reduces drásticamente la superficie de ataque frente a vulnerabilidades. |

---

## 🔗 Enlace al Proyecto

Puedes revisar el código fuente completo y el repositorio original en:
👉 [GitHub - contenedoresMulltistage](https://github.com/diego-col-un/contenedoresMulltistage)
