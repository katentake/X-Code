package main

import (
    "fmt"
    "net/http"
)

func main() {
    // routing path /
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Go Web Hello World!")
    })

    fmt.Println("Server is starting on port 8088...")
    // listen port: 8088
    err := http.ListenAndServe(":8088", nil)
    if err != nil {
        fmt.Printf("Server failed to start: %v\n", err)
    }
}