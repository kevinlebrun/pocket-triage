import * as React from "react";
import { useEffect, useState } from "react";

import { useClient } from "./ClientProvider";
import { Selector } from "./Selector";
import { Link } from "./types";

export const Triage = () => {
  const client = useClient();
  const [links, setLinks] = useState(new Array<Link>());

  if (!client.isAuthenticated()) {
    return (
      <div className="container">
        <p>You are not logged!</p>
        <a href={client.getOauthURL()}>Login to continue</a>
      </div>
    );
  }

  useEffect(() => {
    client.getLinks().then((links) => {
      setLinks(links);
    });
  }, []);

  const deleteHandler = (links: Link[]) => {
    client.deleteLinks(links);
  };

  return <Selector links={links} onDeleteCallback={deleteHandler} />;
};
