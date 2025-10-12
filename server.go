package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/url-parameters", func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(1 * time.Second)
		if err := r.ParseForm(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		for key, vals := range r.Form {
			fmt.Fprintf(w, "%s=%v\n", key, vals)
		}
	})
	log.Fatal(http.ListenAndServe(":8888", nil))
}
