
# --- ETAPA 1: Construcción (Build) ---
# Usamos una imagen oficial de Go que tiene todo el compilador y herramientas.
FROM golang:1.22-alpine AS build

# Definimos el directorio de trabajo dentro del contenedor de build
WORKDIR /app

# Copiamos el código fuente al contenedor
COPY main.go .

# Compilamos el binario de Go de forma estática (optimizada para entornos ligeros)
RUN CGO_ENABLED=0 GOOS=linux go build -o mi-app-go main.go


# --- ETAPA 2: Producción (Run) ---
# Usamos una imagen ultra ligera (Alpine) que solo ocupará unos 5MB.
FROM alpine:latest

# Añadimos un directorio de trabajo en la nueva imagen
WORKDIR /root/

# ¡Aquí está el truco! Copiamos el binario compilado desde la etapa "build"
COPY --from=build /app/mi-app-go .

# Exponemos el puerto en el que corre la app
EXPOSE 8080

# Comando para ejecutar la aplicación
CMD ["./mi-app-go"]
