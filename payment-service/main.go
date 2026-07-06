package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy", "service": "payment"})
}

func payHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	// 从环境变量获取第三方支付网关的秘钥（后续用 K8s Secret 注入）
	apiKey := os.Getenv("PAYMENT_API_KEY")
	fmt.Printf("[Payment] Processing payment using API Key len: %d\n", len(apiKey))

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":        "paid",
		"transaction_id": "TXN-99999",
	})
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/pay", payHandler)

	fmt.Println("Payment Service running on port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}
