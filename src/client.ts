import axios, { AxiosInstance, AxiosResponse } from "axios";

import { Link } from "./types";

class Client {
  private client: AxiosInstance;

  private readonly baseURL: string;

  private token: string;

  public constructor(baseURL: string) {
    this.baseURL = baseURL;
    this.client = axios.create({ baseURL });
    this.token = window.sessionStorage.getItem("token") || "";
    if (this.token.length > 0) {
      axios.defaults.headers.common.token = `${this.token}`;
    }
  }

  public isAuthenticated(): boolean {
    return this.token !== "";
  }

  getOauthURL(): string {
    return `${this.baseURL}/oauth/request`;
  }

  getLinks(): Promise<Link[]> {
    return this.client.get("links").then((response) => {
      let links: Link[] = [];
      for (const [id, rawLink] of Object.entries(response.data.list)) {
        links.push(decodeRawLink(rawLink));
      }
      return links;
    });
  }

  deleteLinks(links: Link[]): Promise<any> {
    return this.client.delete("links", { data: extractIDs(links) });
  }
}

export function decodeRawLink(rawLink): Link {
  return {
    id: rawLink.item_id,
    title: rawLink.given_title || rawLink.given_url,
    url: rawLink.given_url,
    excerpt: rawLink.excerpt || "",
    favorite: rawLink.favorite == "1",
  };
}

export function extractIDs(links: Link[]): string[] {
  let ids: string[] = [];
  for (const l of links) {
    ids.push(l.id);
  }
  return ids;
}

export default Client;
