GrepdataClient

Official Ruby client for Grepdata API.  More info on GrepData APIs can be found 
in the [GrepData docs](www.grepdata.com/docs).

## Installation

    gem install grepdata_client
    gem install typhoeus

or if you use a Gemfile:

    gem 'grepdata_client'
    gem 'typhoeus'

## Publishing Events

The track call allows you to send data into the system, usually from client devices. 
Setup the client with your public token (token) and the endpoint (default_endpoint), 
generally either 'prod' or 'qa', to send data. These can be found in 
[settings](www.grepdata.com/#/settings/account) and 
[endpoints](www.grepdata.com/#/settings/endpoints) respectively. Each track call 
requires a first parameter of event name and a second JSON object with any related 
dimensions you would like to track along with this event. For more info see 
[docs for sending data](www.grepdata.com/docs#sending).

###Example

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:token => "abcdefghijklmnopqrstuvwxyz123456", :default_endpoint => 'prod')
    client.track 'play', data: { :age => 18 }

## Querying Data 

Querying data using the GrepData API is almost as simple as sending it. This time
the client is configured using the private key (api_key) for your account which can 
be found in [settings](www.grepdata.com/#/settings/account). 


### Data Query

Each data request requires a params object including the following fields:
+ **datamart** (string): the name of the datamart to query (endpoint name for timeseries data)
+ **dimensions** (array): all dimensions to query, be sure to include any dimensions being filtered
+ **filters** (JSON): an object containing any filters to apply to the selected dimensions, key is dimension name, value is array of valid options
+ **metrics** (array): all metrics columns you want aggregated and returned
+ **time_interval** (string): the time granularity to breakout, options are h => hour, d => day, m => month
+ **start_date** (string): the inclusive start of the query in format yyyymmddhh00
+ **end_date** (string): the inclusive end of the query in format yyyymmddhh00

The `client.query` call will return a query object which can be executed with the method `get_result` or printed as 
a the complete API url that will be executed with `get_url`.

###Example
From the user_info datamart
Select the hour, country and the total count of events 
Where the country is either US, UK or CA and the event was between 2013/06/11 08:00 and 2013/06/11 09:00
Grouped by hour and country

    require 'rubygems'
    require 'grepdata_client'
        
    client = GrepdataClient::Client.new(:api_key => "abcdefghijklmnopqrstuvwxyz123456")
    
    #Query
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country),
      :metrics => %w(Count),
      :filters => { :country => %w(US UK CA) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }
    req = client.query params
    puts req.get_result

Funneling queries can also be issued from this client. Similar to querying above, the 
client is configured with the api_key and fired with a set of query parameters:
+ **datamart** (string): the name of the datamart to query (endpoint name for timeseries data)
+ **funnel_dimension** (string): the dimension used to identify individual steps in this funnel, usually 'event'
+ **dimensions** (array): all dimensions included in the query, be sure to include any dimensions being filtered and funnel_dimension
+ **filters** (JSON): an object containing any filters to apply to the selected dimensions, key is dimension name, value is array of valid options
+ **metrics** (array): all metrics columns you want aggregated and returned
+ **time_interval** (string): the time granularity upon which to query, should align with start and end date boundaries, options are h => hour, d => day, m => month
+ **start_date** (string): the inclusive start of the query in format yyyymmddhh00
+ **end_date** (string): the inclusive end of the query in format yyyymmddhh00 
+ **steps** (array of JSON): an ordered array containing JSON objects for each step with a friendly display name (name) and the actual dimension value in the data (value) 
+ **only_totals** (boolean): a flag to indicate whether to collapse all data from the given timerange into a single total (true) or leave it broken out by time_interval (false)

###Example
From the demonstration datamart
Select the daily counts of play, pause, seek and stop events 
Where the country is US and the events occurred between 2013/06/12 and 2013/06/19
Broken out by day and country

    require 'rubygems'
    require 'grepdata_client'
        
    client = GrepdataClient::Client.new(:api_key => "abcdefghijklmnopqrstuvwxyz123456")

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
        { :name => "step4: stop", :value => "stop" }
      ],
      :filters => { :country => %w(US) },
      :only_totals => false
    }
    req = client.funneling params
    puts req.get_result
  
## Dimensions Query

Before querying for data, it may be useful to retreive a list of all available dimensions sent to a 
given endpoint.  This can be acheived with the dimensions query, simply by supplying the api_key
and the datamart name.

###Example
Show all dimensions that have been included with events sent to the demonstration endpoint

    require 'rubygems'
    require 'grepdata_client'
    
    client = GrepdataClient::Client.new(:api_key => "abcdefghijklmnopqrstuvwxyz123456")
    
    params = { :endpoint => 'demonstration' }
    req = client.dimensions params
    puts req.get_result
    

##Restricted Queries
While the above method for querying is relatively straight forward, it requires the use of your 
secret api_key, a method which is only suitable for internal or server-side calls since anyone
with this key can access all your account's data. However, it is possible to safely expose a 
controlled subset of the data externally without exposing your secret key.  

We previously discussed the `client.query` call that generates a normal query, but there is also 
a second method `client.safe_url` which will return a simple url using your public token
and a special 'signature' access token in place of the api_key. This url will not have your api_key 
included and so it can safely be passed to a client and called from the client side. The access 
token acts like a checksum, restricting the resulting query to execute only with the parameters 
you specify when calling client.safe_url on the server side.

An optional `expiration` time is also available when generating the safe url generation to restrict 
for how long the url will remain valid.

###Example

    require 'rubygems'
    require 'grepdata_client'
    
    #note that we need to include both the token and api_key. The token can either be in this client initialization or in the params
    client = GrepdataClient::Client.new(:api_key => "abcdefghijklmnopqrstuvwxyz123456", :token => "abcdefghijklmnopqrstuvwxyz123456")
    
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country),
      :metrics => %w(Count),
      :filters => { :country => %w(US) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }
    
    #generate a client safe request that expires at 201312312300
    safe_url = client.safe_query(params, expiration:"201312312300")
       
    puts safe_url
 
## Running Request in Parallel

    require 'rubygems'
    require 'grepdata_client'

    #set parallel to true
    client = GrepdataClient::Client.new(
      :default_endpoint => 'demonstration', 
      :token => "abcdefghijklmnopqrstuvwxyz123456",
      :api_key => "abcdefghijklmnopqrstuvwxyz123456",
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
      :token => "abcdefghijklmnopqrstuvwxyz123456",
      :api_key => "abcdefghijklmnopqrstuvwxyz123456",
      :parallel => true,
      :parallel_manager => hydra)
      
    # query or publish data.  Requests will be queued up
    ...
    
    # this will execute the queued requests as well
    hydra.run

## Copyright

Copyright (c) 2013+ Grepdata. See LICENSE for details.
