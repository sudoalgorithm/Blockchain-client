package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
)

func post(body string) string {
	var url string = "https://polygon-rpc.com/"
	var httpMethod string = "POST"
	var requestBody = []byte(body)
	request, err := http.NewRequest(httpMethod, url, bytes.NewBuffer(requestBody))
	if err != nil {
		panic(err)
	}
	request.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		panic(err)
	}
	defer response.Body.Close()
	responseStatus := string(response.Status)
	responseBody, _ := io.ReadAll(response.Body)
	return responseStatus + "\n" + string(responseBody)
}

func proxyServer(w http.ResponseWriter, r *http.Request) {
	requestBodyOne := []byte(`{
		"jsonrpc": "2.0",
		"method": "eth_blockNumber",
		"id": 2
	  }`)
	requestBodyTwo := []byte(`{
		"jsonrpc": "2.0",
		"method": "eth_getBlockByNumber",
		"params": [
		  "0x134e82a",
		  true
		],
		"id": 2
	  }`)
	fmt.Println(post(string(requestBodyOne)))
	fmt.Println(post(string(requestBodyTwo)))
}

func main() {
	fmt.Println("Server have started on port 3000")
	http.HandleFunc("/", proxyServer)
	http.ListenAndServe(":3000", nil)
}
