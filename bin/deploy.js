// This script will deploy the Greeter contract, and can be used as an example
// for creating your own scripts.

// There are two ways of running scripts with buidler:
//   * The first one is using the command `buidler run <path-to-the-script>`.
//     If you are going to run your scripts like that, you don't need to
//     initialize anything.
//
//   * The other option is to run it directly with node or another node-based
//     tool. You need to `require()` the buidler environment for it to work, and
//     you can optionally inject it to the `global` object.
//
// Note that a script built to be runnable directly with node can also be run
// using `buidler run`.

// These few lines can be omitted if you prefer to use `buidler run <path>`.
const b = require('buidler')

async function main () {
  await b.run('compile')

  const Greeter = b.artifacts.require('Greeter')

  const greeter = await Greeter.new('Hello, buidler!')
  console.log('Greeter address:', greeter.address)
}

main().catch(console.error)
