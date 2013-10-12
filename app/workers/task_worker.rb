class TaskWorker
  include Sidekiq::Worker

  def perform(options)
    task = Task.find(options['task'])

    task_class = "Tasks::" << "#{task.type}_task".camelize
    klass = task_class.constantize.new(task: task, send_mail: false)
    
    yield klass if block_given?

    result = klass.run

    # if result is an error raise it again to have it retried in an hour
    if result.is_a?(Tasks::RetriableError)
      task.running = true
      task.save
      raise result, result.message, result.backtrace
    end
  end

  sidekiq_retries_exhausted do |msg|
    task = Task.find(msg['args']['task'])
    task.running = false
    task.save

    logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end
end