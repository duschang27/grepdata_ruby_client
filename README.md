GrepdataClient

Official Ruby client for Grepdata API.  More info on GrepData APIs can be found 
in the [GrepData docs](https://www.grepdata.com/docs).

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
[settings](https://www.grepdata.com/#/settings/account) and 
[endpoints](https://www.grepdata.com/#/settings/endpoints) respectively. Each track call 
requires a first parameter of event name and a second JSON object with any related 
dimensions you would like to track along with this event. For more info see 
[docs for sending data](https://www.grepdata.com/docs#sending).

###Example

    require 'rubygems'
    require 'grepdata_client'

    client = GrepdataClient::Client.new(:token => "abcdefghijklmnopqrstuvwxyz123456", :default_endpoint => 'prod')
    client.track 'play', data: { :age => 18 }

## Querying Data 

Querying data using the GrepData API is almost as simple as sending it. This time
the client is configured using the private key (api_key) for your account which can 
be found in [settings](https://www.grepdata.com/#/settings/account). 


### Data Query

Each data request requires a params object including the following fields:
+ **datamart** (string - Required): Name of the datamart to query (endpoint name for timeseries data).
+ **dimensions** (array - Required): All dimensions to query, be sure to include any dimensions being filtered.
+ **computed_dimensions** (JSON array): List of any dimensions which have transformation applied on-the-fly at query time.
+ **filters** (JSON): Object containing any filters to apply to the selected dimensions, key is dimension name, value is array of valid options.
+ **metrics** (array - Required): All metrics columns you want aggregated and returned.
+ **time_interval** (string - Required): Time granularity to breakout, options are h => hour, d => day, m => month.
+ **start_date** (string - Required): Inclusive start of the query in format yyyymmddhh00.
+ **end_date** (string - Required): Inclusive end of the query in format yyyymmddhh00.
+ **type** (string): Formatting type for the output, 'full' for one entry per row or 'ui' for a compressed, mapped version.
+ **order_by** (array): Ordered list of dimensions, metrics and/or 'date' indicating the order to return data.
+ **max_rows** (int): Max amount of rows to return back. If the result-set is larger than this max row size, the API will return an error message.
+ **limit** (int): Return the top-n dimension-sets matching the query where n is defined by this parameter. The sorting will be conducted over the total timeperiod, regardless of the time interval (hourly, daily, monthly) chosen. By default, the sorting will occur on the first selected metric, use {limit_by_metric} to change the sort ordering.
+ **limit_after_max** (int): Similar to limit, this value will cause the API to return the top-n rows matching the query if and only if the total rows without limiting would exceed the {max_rows} value (provided or default). Just like {limit}, the sorting will be conducted over the total timeperiod, regardless of the time interval (hourly, daily, monthly) chosen. By default, the sorting will occur on the first selected metric, use {limit_by_metric} to change the sort ordering.
+ **limit_by_metric** (string): Used in conjunction with {limit} to specify the metric to use in sorting the result set. If unset, the sorting will occur on the first selected metric.
+ **offset** (int): Used in conjunction with {limit} and {limit_by_metric} to specify the offset into the results. If unset, the offset is 0, returning the top {limit} results. The offset is 0-indexed, meaning an offset of 5 will ignore the first 5 results and return starting with the 6th. Useful for paging results.
+ **include_remainder** (bool): Used in conjunction with {limit}, {limit_by_metric} and {offset} to determine whether to compute and include a remainder or "Other" entry. If unset or 0, only the top {limit} results will be returned. If set to 1, an extra row will be appended with all the data past top {limit} results aggregated together. If an offset is specified, both the data before {offset} and after {offset} + {limit} will be included.
+ **include_dimension_lists** (bool): If set to true and type=full, the returned json will include a section entitled 'dimensionLists,' a map of dimension name to a list of all values for that dimension in the result set.
+ **include_zero_values** (bool): If set to true and type=full, every returned dimension-set will have a comlete array of values, including entries with metrics of 0 for timeperiods that do not include any data. If false, only the timeperiods and dimensions with data will be returned.

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
a second method `client.get_safe_url` which will return a simple url using your public token
and a special 'signature' access token in place of the api_key. This url will not have your api_key 
included and so it can safely be passed to a client and called from the client side. 

The generated signature acts like a checksum, restricting the resulting query to execute only with 
the restricted parameters you specify when calling `client.get_safe_url` on the server side. By 
default, with no options set, the generated url will be signed such that no modifications are
possible. However, looser restrictions can be applied by passing a `restricted` array to the method.
This array of strings should contain all fields which the client should _not_ be allowed to change. 
All other fields will be modifiable by the client (with the exception of datamart, which can never 
be changed). 

An optional `expiration` time is also available when generating the safe url generation to restrict 
for how long the url will remain valid.

###Example
Generate a url that cannot be modified and a few which can be partially modified

    require 'rubygems'
    require 'grepdata_client'
    
    #note that we need to include both the token and api_key. The token can either be in this client initialization or in the params
    client = GrepdataClient::Client.new(:api_key => "abcdefghijklmnopqrstuvwxyz123456", :token => "abcdefghijklmnopqrstuvwxyz123456")
    
    params =  { 
      :datamart => "user_info",
      :dimensions => %w(country gender),
      :metrics => %w(Count),
      :filters => { :country => %w(US UK), :gender => %w(M) },
      :time_interval => "h",
      :start_date => "201306110800",
      :end_date => "201306110900"
    }
    
    #generate a fully restricted, immutable request that expires at 201312312300
    fully_safe_url = client.get_safe_url(params, expiration:"201312312300")       
    puts fully_safe_url

    #generate a loosely restricted url that allows the client to modify only the dates and interval
    restricted = %w(datamart dimensions metrics filters)
    time_free_safe_url = client.get_safe_url(params, expiration:"201312312300", restricted:restricted)       
    puts time_free_safe_url

    #individual filters may be locked with dot notation without other filters being locked as well
    #this will generate a query which allows the gender filters to be changed but not the country    
    restricted = %w(datamart dimensions metrics filters.country)
    time_and_gender_free_safe_url = client.get_safe_url(params, expiration:"201312312300", restricted:restricted)       
    puts time_and_gender_free_safe_url

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
