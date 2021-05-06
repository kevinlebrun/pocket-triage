import { decodeRawLink, extractIDs } from "./client";

test("decodeRawLink decodes a raw link into a Link", () => {
  const link = decodeRawLink({
    item_id: "1234abc",
    given_url: "http://localhost:8080",
    given_title: "some title",
    excerpt: "some excerpt",
    favorite: "0",
  });
  expect(link.id).toBe("1234abc");
  expect(link.url).toBe("http://localhost:8080");
  expect(link.title).toBe("some title");
  expect(link.excerpt).toBe("some excerpt");
  expect(link.favorite).toBe(false);
});

test("decodeRawLink decodes null excerpt", () => {
  const link = decodeRawLink({});
  expect(link.excerpt).toBe("");
});

test("decodeRawLink replaces empty title by url", () => {
  const link = decodeRawLink({
    given_url: "my_url",
    given_title: "",
  });
  expect(link.title).toBe("my_url");
});

test("decodeRawLink decodes favorite field", () => {
  const link2 = decodeRawLink({
    favorite: "1",
  });
  expect(link2.favorite).toBe(true);
});

test("extractIDs extracts all links ids", () => {
  const ids = extractIDs([
    {
      id: "123a",
      url: "",
      title: "",
      excerpt: "",
      favorite: false,
    },
    {
      id: "456b",
      url: "",
      title: "",
      excerpt: "",
      favorite: false,
    },
  ]);
  expect(ids).toStrictEqual(["123a", "456b"]);
});
