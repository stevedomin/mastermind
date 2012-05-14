README.md
======

*My attempt to a multiplayer Mastermind game with Node.js*

## Overview

A mastermind game built with Node.js, socket.io and backbone.

### Dependencies
* Redis

## To install

```
git clone https://github.com/stevedomin/masterpliz.git
npm install
```

lessc ./public/assets/css/masterpliz.less > ./public/assets/css/masterpliz.css

## To Run

In the root masterpliz directory: `coffee app.coffee`.

## Known issues

* Sometime a new session isn't created when refreshing the browser page then the two players have the same role.

## License

MIT