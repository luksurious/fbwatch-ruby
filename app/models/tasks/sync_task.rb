module Tasks
  class SyncTask
    attr_accessor :gatherer, :task

    NAME = 'sync'
    
    ALL = 'all'

    FEED_KEY_PREV = 'feed_previous_link'
    FEED_KEY_LAST = 'feed_last_link'

    DATA_KEY_RESUME = 'unfinished_resources'

    ERROR_ALREADY_SYNCING = 'ERROR_ALREADY_SYNCING'

    DATA_TIME = 'DATA_TIME'
    SAVE_TIME = 'SAVE_TIME'

    def initialize(koala, options = {})
      @koala = koala

      if options[:task].is_a?(Task)
        use_existing_task(options[:task])
      else
        create_new_task(options)
      end
    end

    def use_existing_task(task)
      @task = task
    end

    def create_new_task(options)
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
      @task.progress = 0.0
      @task.duration = 0
      @task.data = data
      @task.save!

      @task.data[DATA_TIME] = 0
      @task.data[SAVE_TIME] = 0
      
      @total_parts = 1 # that is for a single resource
    end

    def run
      start = Time.now
      
      @task.running = true
      @task.save!

      if task_resumed
        result = resume

      elsif @task.resource.is_a?(Resource)
        result = sync_resource(@task.resource, @task.data)

      elsif @task.resource_group.is_a?(ResourceGroup)
        @total_parts = @task.resource_group.resources.length
        result = sync_resource_collection(@task.resource_group.resources)

      elsif @task.resource_group == ALL
        resources = Resource.where(active: true)
        @total_parts = resources.length
        result = sync_resource_collection(resources)

      else
        raise 'Invalid options provided for SyncTask to run'
      end
      
      @task.running = false
      @task.duration = Time.now - start
      @task.save!

      return result
    end

    private
      def resume
        if @task.resource.is_a?(Resource)
          # syncing of a single resource failed. just do it again
          sync_resource(@task.resource, @task.data)
        else
          # syncing of a collection failed. look into the saved data to resume
          resources = Resource.where(id: @task.data[DATA_KEY_RESUME])
          @total_parts = resources.length
          @progress_modifier = 1.0 - @task.progress
          @start_progress = @task.progress

          # remove resume data
          @task.data[DATA_KEY_RESUME] = nil
          @task.save!

          result = sync_resource_collection(resources)
        end
      end

      def task_resumed
        @task.progress != 0.0
      end

      def part_done
        # doing it that way to come by a full 1.0 if we encounter disabled resources in a collection
        @parts_done ||= 0
        @parts_done += 1

        # if resuming a query we want to gracefully start to count upwards where we left of. otherwise this is 1
        @progress_modifier ||= 1.0

        @task.progress = @parts_done * @progress_modifier / @total_parts
        
        if @progress_modifier != 1.0 and @start_progress.to_i > 0
          @task.progress += @start_progress
        end

        @task.save!
      end

      def sync_resource_collection(collection)

        result = nil
        collection.each do |resource|
          if resource.active == false
            @total_parts -= 1
            next
          end

          if result.is_a?(StandardError)
            # a previous sync encountered a connection error, remember that the current resource was not yet synced
            @task.data[DATA_KEY_RESUME] << resource.id
          else
            result = sync_resource(resource)

            if result.is_a?(StandardError)
              @task.data['failing_resource'] = resource.id
              @task.data[DATA_KEY_RESUME] = [resource.id]
            end
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
          Sync::DataSaver.new(FEED_KEY_PREV, FEED_KEY_LAST).save_resource(resource, result)
        end
        if result.is_a?(Hash)
          part_done
        else
          @task.data['failures'] ||= {}
          @task.data['failures'][resource.id] = result.to_s
        end

        @task.data[DATA_TIME] += data_time
        @task.data[SAVE_TIME] += save_time

        @task.duration += data_time + save_time

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
        rescue => e
          # another nasty error occured
          Rails.logger.error "A connection error occured: #{e.message}"
          return e
        end

        return result
      end

      def setup_gatherer(resource)
        @gatherer = Sync::UserDataGatherer.new(resource.username, @koala)

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