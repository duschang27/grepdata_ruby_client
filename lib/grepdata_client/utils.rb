module GrepdataClient
  module Utils
    def self.date_format
      "%Y%m%d%H%M"
    end
    
    def self.cache_buster
      Time.now.getutc.to_i.to_s
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
        date = DateTime.parse params[attr]
        params[attr] = date.strftime Utils.date_format
      end
    end
    
    def self.format_params(action, params)
      result = {}
      result[:endpoint] = params[:endpoint] if params[:endpoint]
      result[:datamart] = params[:datamart] if params[:datamart]
      result[:metrics] = params[:metrics].join(',') if params[:metrics]
      result[:dimensions] = params[:dimensions].join(',') if params[:dimensions]
      result[:computed_dimensions] = params[:computed_dimensions] if params[:computed_dimensions]
      result[:filters] = params[:filters].to_json if params[:filters]
      result[:time_interval] = params[:time_interval] if params[:time_interval]
      result[:type] = params[:type] if params[:type]
      result[:order_by] = params[:order_by].join(',') if params[:order_by]
      result[:max_rows] = params[:max_rows] if params[:max_rows]
      result[:limit] = params[:limit] if params[:limit]
      result[:limit_after_max] = params[:limit_after_max] if params[:limit_after_max]
      result[:offset] = params[:offset] if params[:offset]    
      if params[:sortMetric]
        limit_by_metric = params[:sortMetric]
      elsif params[:limit_by_metric]
        limit_by_metric = params[:limit_by_metric]
      end
      result[:limit_by_metric] = limit_by_metric if limit_by_metric
      result[:include_remainder] = params[:include_remainder] if params[:include_remainder]    
      result[:include_dimension_lists] = params[:include_dimension_lists] if params[:include_dimension_lists]    
      result[:include_zero_values] = params[:include_zero_values] if params[:include_zero_values]    

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

      result[:signature] = params[:signature] if params[:signature]
      result[:restricted] = params[:restricted] if params[:restricted]
      result[:expiration] = params[:expiration] if params[:expiration]
      
      result
    end
  end
end
