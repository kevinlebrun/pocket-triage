package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"regexp"

	"github.com/gorilla/mux"
)

type AuthRequest struct {
	ConsumerKey string `json:"consumer_key"`
	AccessToken string `json:"access_token"`
}

type GetRequest struct {
	AuthRequest
	State      string `json:"state"`
	DetailType string `json:"detailType"`
	Count      int    `json:"count"`
	Offset     int    `json:"offset"`
}

func main() {
	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/", HandleIndex)
	fs := http.FileServer(http.Dir("static"))
	router.PathPrefix("/static/").Handler(http.StripPrefix("/static/", fs))
	router.HandleFunc("/login", HandleLogin)

	router.HandleFunc("/oauth/request", AuthInit).Methods("GET")
	router.HandleFunc("/oauth/access_token", AuthFetchAccessToken).Methods("GET")

	router.HandleFunc("/sessions", SessionsShow).Methods("GET")
	router.HandleFunc("/sessions", SessionsCreate).Methods("POST")
	router.HandleFunc("/sessions/{id}", SessionShow).Methods("GET")
	router.HandleFunc("/sessions/{id}/links", SessionLinksShow).Methods("GET")
	router.HandleFunc("/sessions/{id}/link", SessionLinkDelete).Methods("DELETE")
	router.HandleFunc("/sessions/{id}/link", SessionLinkUpdate).Methods("PATCH")

	log.Fatal(http.ListenAndServe(":8080", router))
}

func HandleIndex(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "index.html")
}

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "login.html")
}

func AuthInit(w http.ResponseWriter, r *http.Request) {
	values := url.Values{
		"consumer_key": {"51813-9210c4b043da8404cede46e2"},
		"redirect_uri": {"Triage:authorizationFinished"},
	}
	resp, _ := http.PostForm("https://getpocket.com/v3/oauth/request.php", values)

	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)

	code := regexp.MustCompile("^code=(.*)$").FindSubmatch(body)
	if code != nil {
		fmt.Printf("%s\n", code[1])
		http.Redirect(w, r, "https://getpocket.com/auth/authorize?request_token="+string(code[1])+"&redirect_uri=http://localhost:8080/oauth/access_token?request_token="+string(code[1]), 302)
	}
}

func AuthFetchAccessToken(w http.ResponseWriter, r *http.Request) {
	request_token := r.URL.Query().Get("request_token")

	values := url.Values{
		"consumer_key": {"51813-9210c4b043da8404cede46e2"},
		"code":         {request_token},
	}

	resp, _ := http.PostForm("https://getpocket.com/v3/oauth/authorize", values)

	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)

	// TODO handle 403 Forbidden here

	result, _ := url.ParseQuery(string(body))
	fmt.Printf("%+v\n", result)

	request := GetRequest{
		AuthRequest{"51813-9210c4b043da8404cede46e2", result.Get("access_token")},
		"unread",
		"complete",
		100,
		0,
	}

	requestJson, _ := json.Marshal(request)
	url := "https://getpocket.com/v3/get"
	req, _ := http.NewRequest("POST", url, bytes.NewReader(requestJson))

	req.Header.Add("content-type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	w.Header().Add("content-type", "application/json")

	defer res.Body.Close()
	io.Copy(w, res.Body)
}

func SessionsShow(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Sessions...")
}

func SessionsCreate(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Creating a new session...")
}

func SessionShow(w http.ResponseWriter, r *http.Request) {
}

func SessionLinksShow(w http.ResponseWriter, r *http.Request) {
}

func SessionLinkDelete(w http.ResponseWriter, r *http.Request) {
}

func SessionLinkUpdate(w http.ResponseWriter, r *http.Request) {
}
