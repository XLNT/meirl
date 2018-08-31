const proxyFor = target =>
  `0x603160008181600b9039f3600080808080368092803773${target.replace(
    "0x",
    ""
  )}5af43d828181803e808314602f57f35bfd`;

module.exports = {
  proxyFor
};
