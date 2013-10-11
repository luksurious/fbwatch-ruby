module Tasks
  class Base
    attr_accessor :task

    def self.get_active_for(options)
      Task.where(resource_group_id: options[:resource_group] || nil, resource_id: options[:resource] || nil, running: true, type: type_name)
    end
    
    def initialize(options = {})
      if options[:task].is_a?(Task)
        use_existing_task(options[:task])
      else
        create_new_task(options)
      end
    end

    def use_existing_task(task)
      @task = task
      init_data
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
      @task.type = self.class.type_name
      @task.progress = 0.0
      @task.duration = 0
      @task.data = data
      @task.save!

      init_data
    end

    # overwrite me
    def init_data; end

    def run
      start = Time.now
      
      @task.running = true
      @task.save!

      begin
        if task_resumed
          result = resume
        else
          result = task_run
        end
      rescue => error
        Rails.logger.error "Rescued from unexpected error in task #{@task.inspect}: #{error.class} - #{error.message}\n-- " << error.backtrace.join("\n  ")
      end
      
      @task.running = false
      @task.duration += (Time.now - start)
      @task.save!

      return result
    end

    protected
      def task_resumed
        @resumed ||= @task.progress != 0.0
      end

      def part_done
        @total_parts ||= 1 # that is for a single resource
        # doing it that way to come by a full 1.0 if we encounter disabled resources in a collection
        @parts_done ||= 0
        @parts_done += 1

        @start_progress ||= @task.progress

        # if resuming a query we want to gracefully start to count upwards where we left of. otherwise this is 1
        @progress_modifier ||= 1.0

        @task.progress = @parts_done * @progress_modifier / @total_parts
        
        if task_resumed
          @task.progress += @start_progress
        end

        @task.save!
      end
  end
end