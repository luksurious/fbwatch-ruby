class TaskWorker
  include Sidekiq::Worker
  # set the retry count to a rather high value in case we have a very large task which gets a lot of connection issues
  sidekiq_options :retry => 100

  sidekiq_retry_in do |count|
    # retry every minute since in case of request limit reached it might be ok by then
    1.minute.to_i
  end

  def perform(options)
    task = Task.find(options['task'])

    task_class = "Tasks::" << "#{task.type}_task".camelize
    klass = task_class.constantize.new(task: task)
    
    yield klass if block_given?

    result = klass.run

    # if result is an error raise it again to have it retried in an hour
    if result.is_a?(StandardError)
      task.running = true
      task.save
      raise result
    end
  end

  sidekiq_retries_exhausted do |msg|
    task = Task.find(msg['args']['task'])
    task.running = false
    task.save

    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end
end