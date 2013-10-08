module Tasks
  class SyncTask
    attr_accessor :gatherer, :task

    NAME = 'sync'
    
    ALL = 'all'

    FEED_KEY_PREV = 'feed_previous_link'
    FEED_KEY_LAST = 'feed_last_link'

    ERROR_ALREADY_SYNCING = 'ERROR_ALREADY_SYNCING'

    DATA_TIME = 'DATA_TIME'
    SAVE_TIME = 'SAVE_TIME'

    def initialize(koala, options = {})
      @koala = koala

      resource = options[:resource] || nil
      resource_group = options[:resource_group] || nil

      if !options[:data].nil? and !options[:data].is_a?(Hash)
        Rails.logger.warn "Invalid :data value #{options[:data]}, expected Hash"
        options[:data] = {}
      end
      data = options[:data] || {}

      @task = Task.new
      @task.resource = resource
      @task.resource_group = resource_group
      @task.type = NAME
      @task.progress = 0
      @task.data = data
      @task.save!

      @task.data[DATA_TIME] = 0
      @task.data[SAVE_TIME] = 0
    end

    def run
      start = Time.now
      
      @task.running = true
      @task.save!

      if @task.resource.is_a?(Resource)
        result = sync_resource(@task.resource, @task.data)

      elsif @task.resource_group.is_a?(ResourceGroup)
        result = sync_resource_collection(@task.resource_group.resources)

      elsif @task.resource_group == ALL
        result = sync_resource_collection(Resource.where(active: true))

      else
        raise 'Invalid options provided for SyncTask to run'
      end
      
      @task.running = false
      @task.duration = Time.now - start
      @task.progress = 1.0
      @task.save!

      return result
    end

    private
      def sync_resource_collection(collection)
        result = nil
        collection.each do |resource|
          next if resource.active == false

          result = sync_resource(resource)

          if result.is_a?(Koala::Facebook::APIError)
            break
          end
        end

        return result
      end

      def sync_resource(resource, options = {})
        return ERROR_ALREADY_SYNCING if resource_currently_syncing?(resource)

        setup_gatherer(resource)

        result = nil
        data_time = time do
          result = use_gatherer_to_sync(options)
        end

        save_time = time do
          DataSaver.new(FEED_KEY_PREV, FEED_KEY_LAST).save_resource(resource, result)
        end

        @task.data[DATA_TIME] += data_time
        @task.data[SAVE_TIME] += save_time

        return result
      end

      def use_gatherer_to_sync(options)
        @gatherer.page_limit = options["page_limit"] unless options["page_limit"].blank?

        begin
          result = @gatherer.start_fetch((options["pages"] || -1).to_i)
        rescue Koala::Facebook::APIError => e 
          # if we reach this point the exception was thrown at the first call to get the basic information for a resource
          # i.e. not during the loop of getting the feed, this is important because if an error occurs during said loop
          # we want to be able to resume getting data at the point where it occured and not have to reload everything
          # this usually occurs if the request limit is reached (#17) or for any other permanent error
          Rails.logger.error "A connection error occured: #{e.fb_error_message}"
          return e
        end

        return result
      end

      def setup_gatherer(resource)
        @gatherer = UserDataGatherer.new(resource.username, @koala)

        # set query to resume; might be best to push to resource table
        resource_config = Basicdata.where({ resource_id: resource, key: [FEED_KEY_PREV, FEED_KEY_LAST] })
        link_set = false
        resource_config.each do |link_hash|
          if link_hash.key == FEED_KEY_LAST and link_hash.value != ""
            @gatherer.prev_feed_link = link_hash.value
            link_set = true
          elsif link_hash.key == FEED_KEY_PREV and link_set == false
            @gatherer.prev_feed_link = link_hash.value
          end
        end
      end

      def resource_currently_syncing?(resource)
        if resource.last_synced.is_a?(Time) and resource.last_synced > DateTime.now
          return true
        end
      
        resource.last_synced = Time.now.tomorrow
        resource.save!
        return false
      end

      def time
        start = Time.now
        yield
        Time.now - start
      end
  end
end