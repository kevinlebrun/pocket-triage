package main

import (
	"bytes"
	"embed"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"regexp"
	"strings"

	"github.com/gorilla/mux"
)

const consumerKey = "51813-9210c4b043da8404cede46e2"

//go:embed dist
var embededFiles embed.FS

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

var (
 dryRun = flag.Bool("dry-run", false, "Log deletion only")
 live = flag.Bool("live", false, "Use OS local assets")
)

func main() {
	flag.Parse()

	if *dryRun {
		fmt.Println("Running in dry run mode.")
	}

	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/oauth/request", AuthInit).Methods("GET")
	router.HandleFunc("/oauth/access_token", AuthFetchAccessToken).Methods("GET")

	router.HandleFunc("/links", BatchDeleteLinks(*dryRun)).Methods("DELETE")
	router.HandleFunc("/links", FetchAllLinks).Methods("GET")

	router.PathPrefix("/").HandlerFunc(HandleStatic)

	log.Fatal(http.ListenAndServe(":8080", router))
}

func HandleStatic(w http.ResponseWriter, r *http.Request) {
	p := strings.TrimPrefix(r.URL.Path, "/")

	if p == "" {
		p = "index.html"
	}

	handler := http.FileServer(getFileSystem(*live))
	handler.ServeHTTP(w, r)
}

func getFileSystem(live bool) http.FileSystem {
	if live {
		return http.FS(os.DirFS("dist"))
	}

	fsys, err := fs.Sub(embededFiles, "dist")
	if err != nil {
		panic(err)
	}

	return http.FS(fsys)
}

func AuthInit(w http.ResponseWriter, r *http.Request) {
	values := url.Values{
		"consumer_key": {consumerKey},
		"redirect_uri": {"Triage:authorizationFinished"},
	}
	resp, _ := http.PostForm("https://getpocket.com/v3/oauth/request.php", values)

	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)

	code := regexp.MustCompile("^code=(.*)$").FindSubmatch(body)
	if code != nil {
		http.Redirect(w, r, "https://getpocket.com/auth/authorize?request_token="+string(code[1])+"&redirect_uri=http://localhost:8080/oauth/access_token?request_token="+string(code[1]), 302)
	}
}

func AuthFetchAccessToken(w http.ResponseWriter, r *http.Request) {
	request_token := r.URL.Query().Get("request_token")

	values := url.Values{
		"consumer_key": {consumerKey},
		"code":         {request_token},
	}

	resp, _ := http.PostForm("https://getpocket.com/v3/oauth/authorize", values)

	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)

	result, _ := url.ParseQuery(string(body))

	http.Redirect(w, r, "http://localhost:8080?access_token="+result.Get("access_token"), 302)
}

func FetchAllLinks(w http.ResponseWriter, r *http.Request) {
	request := GetRequest{
		AuthRequest{consumerKey, r.Header.Get("token")},
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

func BatchDeleteLinks(dryRun bool) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		body, _ := ioutil.ReadAll(r.Body)

		var ids []string

		// FIXME(kevin.lebrun): handle errors
		json.Unmarshal(body, &ids)

		var actions []Action
		for _, id := range ids {
			actions = append(actions, Action{id, "delete"})
		}

		request := DeleteRequest{
			AuthRequest{consumerKey, r.Header.Get("token")},
			actions,
		}

		// FIXME(kevin.lebrun): handle errors
		requestJson, _ := json.Marshal(request)
		url := "https://getpocket.com/v3/send"
		req, _ := http.NewRequest("POST", url, bytes.NewReader(requestJson))

		req.Header.Add("content-type", "application/json")

		if dryRun {
			dump, _ := httputil.DumpRequest(req, true)
			fmt.Printf("%s\n", dump)

			w.Header().Add("content-type", "application/json")

			res := map[string]interface{}{
				"done": true,
			}
			json.NewEncoder(w).Encode(res)
			return
		}

		res, _ := http.DefaultClient.Do(req)

		w.Header().Add("content-type", "application/json")

		defer res.Body.Close()
		io.Copy(w, res.Body)
	}
}
