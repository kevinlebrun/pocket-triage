import { useEffect, useRef, useState } from "react";
import * as React from "react";

import { Link } from "./types";
import classNames from "classnames";

const perPage = 10;

function useEventListener(eventName, handler, element = window) {
  // Create a ref that stores handler
  const savedHandler = useRef();

  // Update ref.current value if handler changes.
  // This allows our effect below to always get latest handler ...
  // ... without us needing to pass it in effect deps array ...
  // ... and potentially cause effect to re-run every render.
  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(
    () => {
      // Make sure element supports addEventListener
      // On
      const isSupported = element && element.addEventListener;
      if (!isSupported) return;

      // Create event listener that calls handler function stored in ref
      const eventListener = (event) => {
        // @ts-ignore
        savedHandler.current(event);
      };

      // Add event listener
      element.addEventListener(eventName, eventListener);

      // Remove event listener on cleanup
      return () => {
        element.removeEventListener(eventName, eventListener);
      };
    },
    [eventName, element] // Re-run if eventName or element changes
  );
}

interface LinkProps {
  link: Link;
  selected: boolean;
  keep: boolean;
}

const Link = ({ link, selected, keep }: LinkProps) => {
  const clss = classNames({
    link: true,
    "link--selected": selected,
    "link--keep": keep,
    "link--favorite": link.favorite,
  });

  return (
    <div className={clss}>
      <a href={link.url} target="_blank">
        {link.title}
      </a>
      <p className="link__excerpt">{link.excerpt}</p>
    </div>
  );
};

interface SelectorProps {
  links: Link[];
  onDeleteCallback: (links: Link[]) => void;
}

export const Selector = ({ links, onDeleteCallback }: SelectorProps) => {
  let [done, setDone] = useState(false);
  let [deleted, setDeleted] = useState(0);
  let [page, setPage] = useState(1);
  let [selected, setSelected] = useState(0);
  let [keep, setKeep] = useState(new Set<Link>());

  const snapshot = links.slice(
    (page - 1) * perPage,
    (page - 1) * perPage + perPage
  );

  const nextPage = () => {
    setPage(page + 1);
    let toDelete: Link[] = [];
    for (const link of snapshot) {
      if (keep.has(link) || link.favorite) {
        continue;
      }
      toDelete.push(link);
    }
    setDeleted(deleted + toDelete.length);
    setKeep(new Set<Link>());
    setSelected(0);
    onDeleteCallback(toDelete);
    if (page == Math.ceil(links.length / perPage)) {
      setDone(true);
    }
  };

  const handleKeys = (e) => {
    switch (e.key) {
      case " ":
        const current = snapshot[selected];
        if (keep.has(current)) {
          keep.delete(current);
          setKeep(new Set(keep));
        } else {
          setKeep(new Set(keep.add(current)));
        }
        e.preventDefault();
        break;
      case "j":
        // down
        if (selected < perPage - 1) {
          setSelected(selected + 1);
        }
        e.preventDefault();
        break;
      case "k":
        // up
        if (selected > 0) {
          setSelected(selected - 1);
        }
        e.preventDefault();
        break;
      case "Enter":
        nextPage();
        // flush all kept to deleted
        e.preventDefault();
        break;
    }
  };

  useEventListener("keydown", handleKeys);

  if (done) {
    return (
      <div className="container">
        <p>Well done! You went through all of your items.</p>
        <p>You deleted {deleted} items.</p>
      </div>
    );
  }

  return (
    <div className="container">
      {links.length == 0 && <p>Loading...</p>}

      {links.length > 0 && (
        <>
          <div>
            <p className="stats__summary">
              page {page} of {Math.ceil(links.length / perPage)}, {links.length}{" "}
              items
            </p>
            <p className="stats__progress">{deleted} deleted</p>
          </div>

          <div className="links">
            {snapshot.map((l: Link, i) => (
              <Link
                key={l.id}
                link={l}
                selected={selected == i}
                keep={keep.has(l)}
              />
            ))}
          </div>

          <input type={"button"} onClick={nextPage} value="Next" />
        </>
      )}
    </div>
  );
};
