expose:
  # this isn't actually used with getUpdates; only useful with webhooks
  ssh -v -N -R 4050:localhost:4050 lb
