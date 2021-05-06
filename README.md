# Pocket Triage

A simple way to clean up your Pocket links in close to no time.

## Usage

Build binary:

    $ npm install
    $ npx parcel build index.html
    $ go build *.go
    $ ./server

Then open your browser to `http://localhost:8080`.

Use `j` and `k` to select an article. Press the space key to whitelist the selected article. Press the return key or `Next` to go to the next page.

Note: Articles are deleted from `Pocket` at the end of each pages. The operation is irreversible.

## Test

    $ go run *.go --dry-run --live
    $ npm run start

Then open your browser to `http://localhost:8080`.

Run test using `jest`:

    $ npx jest

Format code before pushing:

    $ npx prettier --write

## License

The MIT license
