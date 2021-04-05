const glob = require('glob')
const { statSync } = require('fs')
const { readFile: read, writeFile: write } = require('fs/promises')
const compress = require('brotli/compress')
const { promisify } = require('util')
const skipSizeUnderBytes = 10000
const dir = './dist/**'

const settings = {
  extension: 'br',
  skipLarger: true,
  mode: 1, // 0 = generic, 1 = text, 2 = font (WOFF2)
  quality: 10, // 0 - 11,
  lgwin: 12, // default
}

promisify(glob)(dir)
  .then(files =>
    files
      .filter(file => file.match(/^.+\.(js|css|html)$/))
      .filter(file => statSync(file).size > skipSizeUnderBytes)
      .map(async file => [`${file}.br`, compress(await read(file), settings)])
      .map(async args => await write(...(await args)))
  )
  .then(results => Promise.all(results))
  .catch(console.error)
