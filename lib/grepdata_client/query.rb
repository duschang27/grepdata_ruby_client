module GrepdataClient
  class DataRequest
    attr_reader :request, :base_url, :params, :headers, :action
    
    def initialize(action, options)
      @action = action.to_s
      @base_url = "#{options[:url]}/#{@action}"
      @params = options[:params] || {}
      @headers = options[:headers] || {}
      
      params = Utils.format_params @action, @params

      @request = ::Typhoeus::Request.new(@base_url, params: params, headers: @headers)
    end
    
    def get_result
      return @request.response.body
    end
    
    def get_url
      return @request.url
    end
  end
end
