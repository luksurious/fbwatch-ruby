class TaskWorker
  include Sidekiq::Worker

  def perform(task_id)
    task = Task.find(task_id)

    task_class = "Tasks::" << "#{task.type}_task".camelize
    klass = task_class.constantize.new(task: task)
    
    yield klass if block_given?

    result = klass.run

    # if result is error delay and run again if appropriate
  end
end