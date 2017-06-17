#!/usr/bin/env ruby

require 'rest-client'
require 'open-uri'
require 'redis'
require 'json'

ETH_PRICE_KEY = 'eth_aud_price'
CACHE_EXPIRE_MINUTES = 15

redis = Redis.new
cache_price = redis.get ETH_PRICE_KEY

if cache_price.nil?
  response = RestClient.get 'https://api.btcmarkets.net/market/ETH/AUD/tick',
                            accept: 'application/json'
  case response.code
    when 200
      market = JSON.parse(response)
      current_price = market['lastPrice']
      redis.set ETH_PRICE_KEY, current_price, ex: (60 * CACHE_EXPIRE_MINUTES)
    else
      current_price = 'ERROR!'
  end
else
  current_price = cache_price
end

puts '♦ ETH/AUD ' + current_price.to_s
