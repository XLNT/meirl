module.exports = {
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    test: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*', // eslint-disable-line camelcase
    },
  },
}
