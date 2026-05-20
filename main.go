package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "¡Hola! Estás viendo una aplicación Go en un contenedor multi-stage. 🚀")
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Servidor corriendo en el puerto 8080...")
	http.ListenAndServe(":8080", nil)
}
