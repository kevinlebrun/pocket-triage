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
	"strings"

	"github.com/gorilla/mux"
)

const consumer_key = "51813-9210c4b043da8404cede46e2"

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

type Action struct {
	ItemID string `json:"item_id"`
	Action string `json:"action"`
}

type DeleteRequest struct {
	AuthRequest
	Actions []Action `json:"actions"`
}

type Item struct {
	Id    string `json:"id"`
	Title string `json:"title"`
	URL   string `json:"url"`
}

func main() {
	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/oauth/request", AuthInit).Methods("GET")
	router.HandleFunc("/oauth/access_token", AuthFetchAccessToken).Methods("GET")

	router.HandleFunc("/links", BatchDeleteLinks).Methods("DELETE")
	router.HandleFunc("/links", FetchAllLinks).Methods("GET")

	router.PathPrefix("/").HandlerFunc(HandleStatic)

	log.Fatal(http.ListenAndServe(":8080", router))
}

func HandleStatic(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/")

	if path == "" {
		path = "index.html"
	}

	data, err := Asset(path)
	if err != nil {
		w.WriteHeader(404)
		return
	}

	io.Copy(w, bytes.NewReader(data))
}

func AuthInit(w http.ResponseWriter, r *http.Request) {
	values := url.Values{
		"consumer_key": {consumer_key},
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

// TODO handle 403
func AuthFetchAccessToken(w http.ResponseWriter, r *http.Request) {
	request_token := r.URL.Query().Get("request_token")

	values := url.Values{
		"consumer_key": {consumer_key},
		"code":         {request_token},
	}

	resp, _ := http.PostForm("https://getpocket.com/v3/oauth/authorize", values)

	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)

	result, _ := url.ParseQuery(string(body))
	fmt.Printf("%+v\n", result)

	http.Redirect(w, r, "http://localhost:8080?access_token="+result.Get("access_token"), 302)
}

func FetchAllLinks(w http.ResponseWriter, r *http.Request) {
	request := GetRequest{
		AuthRequest{consumer_key, r.Header.Get("token")},
		"unread",
		"complete",
		5000,
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

func BatchDeleteLinks(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	body, _ := ioutil.ReadAll(r.Body)

	var items []Item
	var actions []Action

	json.Unmarshal(body, &items)

	for _, item := range items {
		actions = append(actions, Action{item.Id, "delete"})
	}

	request := DeleteRequest{
		AuthRequest{consumer_key, r.Header.Get("token")},
		actions,
	}

	requestJson, _ := json.Marshal(request)
	url := "https://getpocket.com/v3/send"
	req, _ := http.NewRequest("POST", url, bytes.NewReader(requestJson))

	req.Header.Add("content-type", "application/json")

	res, _ := http.DefaultClient.Do(req)

	w.Header().Add("content-type", "application/json")

	defer res.Body.Close()
	io.Copy(w, res.Body)
}
