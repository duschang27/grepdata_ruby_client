module GrepdataClient
  module Utils
    def self.date_format
      "%Y%m%d%H00"
    end
    
    def self.default_expiration
      (Time.now.utc + (24*60*60)).strftime Utils.date_format
    end
    
    def self.generate_key(api_key, options)
      identity = "#{options[:datamart]}\n"
      identity += "#{options[:values]}\n" if options[:values].length > 0
      identity += options[:expiration]
      
      #hash identity using HMAC-SHA1.  return as base64 encoded string
      Base64.encode64(OpenSSL::HMAC.digest('sha1', api_key, identity)).chomp
    end
  
    def self.check_attributes(name, options)
      params  = options[:params]
      required = options[:required]
      
      missing = []
      required.each_key do |key|
        if not params[key].is_a? required[key]
          message = "#{name} missing required attribute #{key.to_s} of type #{required[key].name}"
          missing.push message
          puts "Warning: #{message}"
        end
      end
      raise "Error: #{name} missing required attributes" if missing.length > 0
    end
    
    def self.preprocess_dates(params, attributes)
      attributes.each do |attr|
        date = Date.parse params[attr]
        params[attr] = date.strftime Utils.date_format
      end
    end
    
    def self.format_params(action, params)
      result = {}
      result[:endpoint] = params[:endpoint] if params[:endpoint]
      result[:datamart] = params[:datamart] if params[:datamart]
      result[:metrics] = params[:metrics].join(',') if params[:metrics]
      result[:dimensions] = params[:dimensions].join(',') if params[:dimensions]
      result[:filters] = params[:filters].to_json if params[:filters]
      result[:time_interval] = params[:time_interval] if params[:time_interval]
    
      if action == "funneling"
        steps = []
        params[:steps].each do |step|
          step[:start_date] = params[:start_date]
          step[:end_date] = params[:end_date]
          steps.push step
        end
        result[:steps] = { :steps => steps }.to_json
        result[:funnel_dimension] = params[:funnel_dimension]
      else
        result[:start_date] = params[:start_date]
        result[:end_date] = params[:end_date]
      end
    
      result[:api_key] = params[:api_key] if params[:api_key]
      result[:token] = params[:token] if params[:token]
      result
    end
  end
end