class TasksController < ApplicationController
  before_action :set_task_by_id, only: [:resume_task, :mark_error]

  def index
    raw_tasks = Task.order(type: :asc, running: :asc, created_at: :desc)

    @tasks = {}
    raw_tasks.each do |task|
      @tasks[task.type] ||= {active: [], finished: [], halted: []}

      if task.running
        @tasks[task.type][:active] << task
      elsif task.progress < 1.0 and task.error == false
        @tasks[task.type][:halted] << task
      else
        @tasks[task.type][:finished] << task
      end
    end
  end

  # this should be refactored
  def resume_task
    # check if resumable
    if @task.type != 'sync' or # right now only sync is possible
       @task.progress >= 1
      flash[:warning] << "Cannot resume task \##{@task.id}, not resumable"
      redirect_to tasks_path and return
    end

    SyncTaskWorker.perform_async('token' => session[:facebook].access_token, 'task' => @task.id)
    
    flash[:notice] << 'This task is now resumed.'
    redirect_to tasks_path and return
  end

  def mark_error
    @task.error = true
    @task.running = false

    if @task.save
      flash[:notice] << 'Task is now marked as faulty.'
    else
      flash[:warning] << 'Unable to mark task as faulty.'
    end
  
    redirect_to tasks_path
  end

  private
    def set_task_by_id
      @task = Task.find(params[:id])
    end
end
