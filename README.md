# GrepdataClient

TODO: Write a gem description

## Installation

    gem install grepdata_client

or if you use a Gemfile:

    gem 'grepdata_client'

## Basic Usage

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

## Generate access key

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

## Query with access key

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

## Copyright

Copyright (c) 2013+ Grepdata. See LICENSE for details.
