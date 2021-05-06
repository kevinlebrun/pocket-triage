import * as React from "react";
import * as ReactDOM from "react-dom";

import { Triage } from "./Triage";
import ClientProvider from "./ClientProvider";

const queryParams = new URLSearchParams(location.search);

if (queryParams.has("access_token")) {
  window.sessionStorage.setItem("token", queryParams.get("access_token"));
  queryParams.delete("access_token");
  window.location.search = queryParams.toString();
}

const defaultBaseURL = "http://localhost:8080";

const Root = (
  <ClientProvider baseURL={process.env.BASE_URL || defaultBaseURL}>
    <Triage />
  </ClientProvider>
);

ReactDOM.render(Root, document.getElementById("triage-ui"));
