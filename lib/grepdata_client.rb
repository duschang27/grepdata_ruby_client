require "typhoeus"
require 'base64'
require 'openssl'
require 'json'
require 'Date'

require "grepdata_client/version"
require "grepdata_client/query"
require "grepdata_client/utils"

module GrepdataClient
  class Client
  
    attr_accessor :api_url, :api_key, :token, :parallel, :parallel_manager
    
    CONFIG = {
      :api_url => "https://api.grepdata.com/v1",
    }
    
    def initialize(config)
      @api_key, @token = config.values_at(:api_key, :token) 
      @api_url = config[:api_url] || CONFIG[:api_url]
      @parallel = config[:parallel] || false
      if config[:parallel_manager]
        @parallel_manager = config[:parallel_manager] 
      end
    end

    def query(params)
      params[:api_key] = params[:api_key] || @api_key
      params[:filters] = params[:filters] || {}
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      
      Utils.check_attributes "params", 
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
    
    def funneling(params)
      params[:api_key] = params[:api_key] || @api_key
      params[:filters] = params[:filters] || {}
      params[:only_totals] = params[:only_totals] || false
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      
      Utils.check_attributes "params",
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
      
      Utils.check_attributes "params",
        params: params,
        required: { 
          api_key: String, 
          endpoint: String
        }
              
      request(__method__, params: params)
    end
    
    def query_with_token(params, access_key)
      params[:token] = params[:token] || @token
      params[:filters] = params[:filters] || {}
      
      Utils.preprocess_dates params, [:start_date, :end_date]
      Utils.preprocess_dates access_key, [:expiration]
      
      Utils.check_attributes "params", 
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
      
      request('fetch', params: params, headers: access_key)
    end
    
    def run_requests
      @parallel_manager.run if @parallel_manager
    end
            
    def request(action, options)      
      query = Grepdata::Client::DataRequest.new action, 
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
