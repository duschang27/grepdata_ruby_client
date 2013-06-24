require "typhoeus"
require 'base64'
require 'openssl'
require 'json'
require 'date'

require "grepdata_client/version"
require "grepdata_client/query"
require "grepdata_client/utils"

module GrepdataClient
  class Client
  
    attr_accessor :api_url, :api_key, :token, :send_with_headers,
      :default_endpoint, :endpoint_map,
      :parallel, :parallel_manager
    
    CONFIG = {
      :api_url => "https://api.grepdata.com/v1",
      :beacon_url => "https://beacon.grepdata.com/v1"
    }
    
    def initialize(config)
      @api_key, @token, @default_endpoint = 
        config.values_at(:api_key, :token, :default_endpoint) 
        
      @send_with_headers = config[:send_with_headers] || false
      @endpoint_map = config[:endpoint_map] || {}
      @api_url = config[:api_url] || CONFIG[:api_url]
      @beacon_url = config[:beacon_url] || CONFIG[:beacon_url]
      
      @parallel = config[:parallel] || false
      
      if config[:parallel_manager]
        @parallel_manager = config[:parallel_manager] 
      end
    end
    
    def track(event, options)
      token = options[:token] || @token
      endpoint = @endpoint_map[event.to_sym] || @endpoint_map[event] || @default_endpoint
      data = options[:data]
      
      Utils.check_attributes "Request", 
        params: { token: token, endpoint: endpoint, data: data},
        required: {
          token: String,
          endpoint: String,
          data: Hash
        }
    
      params = {
        event: event,
        q: data.to_json,
        cb: Utils.cache_buster,
        token: token
      }
      
      params[:t] = options[:timestamp] if options[:timestamp]
      params[:domain] = options[:domain] if options[:domain]
      params[:ua] = options[:user_agent] if options[:user_agent]
      params[:r] = options[:referer] if options[:referer]
      params[:ip] = options[:ip] if options[:ip]
      params[:visitor] = options[:visitor] if options[:visitor]
      params[:session] = options[:session] if options[:session]
      
      url = "#{@beacon_url}/#{endpoint}"
      
      request = Typhoeus::Request.new url, params: params, timeout: 5
      
      if @parallel
        unless @parallel_manager
          @parallel_manager = ::Typhoeus::Hydra.new 
        end
        @parallel_manager.queue request
      else
        request.run
      end
      
      request
    end

    def query(params)
      params[:api_key] = params[:api_key] || @api_key
      params[:filters] = params[:filters] || {}
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      
      Utils.check_attributes "Request", 
        params: params,
        required: {
          api_key: String, 
          datamart: String,
          dimensions: Array,
          metrics: Array,
          filters: Hash,
          time_interval: String,
          start_date: String,
          end_date: String
        }
        
      request(__method__, params: params)
    end
    
    def safe_query(params, options={})
      params[:token] = params[:token] || @token
      api_key = params[:api_key] || @api_key
      params.delete(:api_key)
      params[:filters] = params[:filters] || {}
      expiration = options[:expiration] || Utils.default_expiration
      
      restricted = ["datamart", "dimensions", "metrics", "filters", "time_interval", "start_date", "end_date"]
   
      access_key = generate_access_key(api_key, params:params, restricted:restricted, expiration:expiration)
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      Utils.preprocess_dates access_key, [:expiration]      

      Utils.check_attributes "Request", 
        params: params,
        required: {
          token: String, 
          datamart: String,
          dimensions: Array,
          metrics: Array,
          filters: Hash,
          time_interval: String,
          start_date: String,
          end_date: String
        }
      
      Utils.check_attributes "access_key",
        params: access_key,
        required: { 
          signature: String, 
          restricted: String,
          expiration: String
        }
        
      params[:signature] = access_key[:signature]
      params[:restricted] = access_key[:restricted]
      params[:expiration] = access_key[:expiration]
      
      query = GrepdataClient::DataRequest.new "fetch", 
                url: @api_url, 
                params: params

      query.get_url
    end
    
    def funneling(params)
      params[:api_key] = params[:api_key] || @api_key
      params[:filters] = params[:filters] || {}
      params[:only_totals] = params[:only_totals] || false
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      
      Utils.check_attributes "Request",
        params: params,
        required: {
          api_key: String, 
          datamart: String,
          funnel_dimension: String,
          dimensions: Array,
          metrics: Array,
          filters: Hash,
          time_interval: String,
          start_date: String,
          end_date: String,
          steps: Array
        }  
      
      request(__method__, params: params)
    end
    
    def dimensions(params)
      params[:api_key] = params[:api_key] || @api_key
      
      Utils.check_attributes "Request",
        params: params,
        required: { 
          api_key: String, 
          endpoint: String
        }
              
      request(__method__, params: params)
    end
    
    def run_requests
      @parallel_manager.run if @parallel_manager
    end
            
    def request(action, options)      
      query = GrepdataClient::DataRequest.new action, 
                url: @api_url, 
                params: options[:params], 
                headers: options[:headers]
      
      if @parallel
        unless @parallel_manager
          @parallel_manager = ::Typhoeus::Hydra.new 
        end
        @parallel_manager.queue query.request
      else
        query.request.run
      end
      
      return query
    end
    
    def generate_access_key(api_key, options)
      restricted = options[:restricted] || []
      expiration = options[:expiration] || Utils.default_expiration
      
      params = options[:params] || options[:request].params
      params = Utils.format_params 'query', params
      
      datamart = params[:datamart]
      
      values = ""
      restricted.each do |param|
        value = params
        segments = param.split(".")
        segments.each do |segment|
          value = JSON.parse value if value.is_a? String
          value = value[segment.to_sym] || value[segment]
        end
        value = segments.length > 1? value.to_json : value.to_s
        values += "&" if values.length > 0
        values += "#{param}=#{value}"
      end

      scope = "datamart=#{datamart}"
      scope += "&#{values}" if 
      signature = Utils.generate_key(api_key, 
        datamart: datamart, 
        values: values,
        expiration: expiration)
  
      return {
        :signature => signature,
        :restricted => restricted.join(','),
        :expiration => expiration.to_s,
        :scope => scope
      }
    end
  end
end

