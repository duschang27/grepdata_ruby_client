# GrepdataClient

Official Ruby client for Grepdata API

## Installation

    gem install grepdata_client

or if you use a Gemfile:

    gem 'grepdata_client'
    
## Publishing Events

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:token => "054a9c9ade7dcf325a3aab542ebd73b5", :default_endpoint => 'demonstration')
    client.track 'play', data: { age: 18 }

## Querying Data 

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:api_key => "0ac15f3688987af763c67412066e3378")
    
    #Query
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country),
      :metrics => %w(Count),
      :filters => { :country => %w(US) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }
    req = client.query params
    puts req.get_result

    #Funneling
    params = { 
      :datamart => 'demonstration',
      :funnel_dimension => 'event',
      :time_interval => 'd',
      :dimensions => %w(event country),
      :metrics => %w(Count),
      :start_date => "201306120000",
      :end_date => "201306190000",  
      :steps => [
        { :name => "step1: play", :value => "play" },
        { :name => "step2: pause", :value => "pause" },
        { :name => "step3: seek", :value => "seek" },
        { :name => "step2: stop", :value => "stop" }
      ],
      :filters => { :country => %w(US) },
      :only_totals => false
    }
    req = client.funneling params
    puts req.get_result

## Generating access key

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:api_key => "0ac15f3688987af763c67412066e3378")
    
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country),
      :metrics => %w(Count),
      :filters => { :country => %w(US) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }
    
    access_key = client.generate_access_key api_key, 
      params: params, 
      restricted: ['dimensions', 'filters.country'],
      expiration: '201306220100'
      
    puts access_key

## Querying with access key

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:token => "054a9c9ade7dcf325a3aab542ebd73b5")
    
    #acquired via generate_access_key
    access_key = {
      :signature=>"0xBBKoaUe6RZSLM//6yqzbYelmI=", 
      :restricted=>"dimensions,filters.country", 
      :expiration=>"201306220100", 
    }
    
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country),
      :metrics => %w(Count),
      :filters => { :country => %w(US) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }

    req = client.query_with_token params, access_key
    puts req.get_result
    
    #get url of the request
    puts req.get_url

## Running Request in Parallel

    require 'rubygems'
    require 'grepdata_client'

    #set parallel to true
    client = GrepdataClient::Client.new(
      :default_endpoint => 'demonstration', 
      :token => "054a9c9ade7dcf325a3aab542ebd73b5",
      :api_key => "0ac15f3688987af763c67412066e3378",
      :parallel => true)
    
    # query or publish data.  Requests will be queued up
    ...
    
    # execute the queued requests and run them in parallel
    client.run_requests
    
We use Typhoeus to handle parallel requests.  You can also pass in your own hydra queue

    require 'rubygems'
    require 'grepdata_client'

    #set parallel to true and pass in hydra queue
    hydra = ::Typhoeus::Hydra.new
    client = GrepdataClient::Client.new(
      :default_endpoint => 'demonstration', 
      :token => "054a9c9ade7dcf325a3aab542ebd73b5",
      :api_key => "0ac15f3688987af763c67412066e3378",
      :parallel => true,
      :parallel_manager => hydra)
      
    # query or publish data.  Requests will be queued up
    ...
    
    # this will execute the queued requests as well
    hydra.run

## Copyright

Copyright (c) 2013+ Grepdata. See LICENSE for details.
