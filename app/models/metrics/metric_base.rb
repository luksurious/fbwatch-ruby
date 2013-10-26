require 'digest/md5'

module Metrics
  class MetricBase
    @@resource_metrics = ['ResourceStats', 'SingleUsersMetric', 'FeedTimeline']
    @@group_metrics = ['SharedResourcesMetric', 'GroupMentions', 'GoogleMentions']

    def self.single_metrics
      @@resource_metrics
    end

    def self.group_metrics
      @@group_metrics
    end

    attr_accessor :metrics, :resource, :resource_group

    def initialize(options = {})
      set_options(options)

      @metrics = []
    end

    def resource_combinations(size)
      if !self.resource_group.nil? and self.resource_group.resources.length > 1
        return self.resource_group.resources.to_a.combination(size).to_a
      end
      
      []
    end

    def get_combination_token(combination)
      Digest::MD5.hexdigest(combination.map{ |res| "#{res.id}.#{res.username}"  }.join('_'))
    end

    def set_options(options)
      @resource = options[:resource]
      @resource_group = options[:resource_group]
    end

    def class_name
      self.class.name.demodulize.underscore
    end

    def make_metric_model(name, value)
      metric = Metric.where({ metric_class: self.class_name, name: name, resource_id: @resource.id }).first_or_initialize

      metric.value = value
      
      @metrics.push(metric)
    end

    def make_group_metric_model(options)
      # TODO sanity checks maybe?
      metric = GroupMetric.where({ 
        metric_class: self.class_name, 
        name: options[:name], 
        resources_token: options[:token], 
        resource_group_id: @resource_group.id 
        }).first_or_initialize

      metric.value = options[:value]

      options[:resources].each do |res|
        metric.resources << res unless metric.resources.include?(res)
      end
      metric.resources.each do |res|
        metric.resources.delete(res) unless options[:resources].include?(res)
      end

      @metrics.push(metric)
      #if !metric.save
      #  Rails.logger.error "Couldn't save metric #{options[:name]} (errors: #{metric.errors.full_messages}"
      #end
    end

    def set(collection)
      @metrics = collection
      self
    end

    def keywords
      if @keywords.nil?
        @keywords = {}
        self.resource_group.resources.each do |res|
          custom_keywords = Basicdata.where(resource_id: res.id, key: 'keywords').pluck(:value).first

          @keywords[res.id] = [
            res.name,
            res.username,
            res.facebook_id
          ]

          unless custom_keywords.nil?
            custom_keywords.split(',').each do |key|
              @keywords[res.id] << key.strip
            end
          end
        end
      end

      @keywords
    end
  end
end