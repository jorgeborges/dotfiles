#!/usr/bin/env ruby

require 'rest-client'
require 'open-uri'
require 'redis'
require 'json'

ETH_PRICE_KEY = 'eth_aud_price'
CACHE_EXPIRE_MINUTES = 15

redis = Redis.new
price = redis.get ETH_PRICE_KEY

if price.nil?
  response = RestClient.get 'https://api.btcmarkets.net/market/ETH/AUD/tick',
                            accept: 'application/json'
  case response.code
    when 200
      market = JSON.parse response
      price = market['lastPrice']
      redis.set ETH_PRICE_KEY, price, ex: (60 * CACHE_EXPIRE_MINUTES)
    else
      price = 'err'
  end
end

puts '♦ ETH/AUD ' + price.to_s
