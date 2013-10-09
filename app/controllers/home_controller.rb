class HomeController < ApplicationController
  before_action :assert_auth, only: [:index]

  def index
    index_groups
  end

  def index_groups
    @resource_groups = ResourceGroup.order(:group_name)
    @resource_group = ResourceGroup.new
    @total_groups = ResourceGroup.count

    respond_to do |format|
      format.html { render template: "home/groups" }
      format.json { render json: @resources }
    end
  end

  def tasks
    raw_tasks = Task.order(type: :asc, running: :asc, created_at: :asc)

    @tasks = {}
    raw_tasks.each do |task|
      @tasks[task.type] ||= {active: [], finished: [], halted: []}

      if task.running
        @tasks[task.type][:active] << task
      elsif task.progress < 1.0
        @tasks[task.type][:halted] << task
      else
        @tasks[task.type][:finished] << task
      end
    end
  end

  def resume_task
    task = Task.find(params[:id])

    # check if resumable
    if task.type != 'sync' or # right now only sync is possible
       task.progress >= 1 or
       (!task.resource_group.nil? and
          task.data[Tasks::SyncTask::DATA_KEY_RESUME].empty?)
      flash[:warning] << "Cannot resume task \##{task.id}, not resumable"
      redirect_to tasks_path and return
    end

    Tasks::SyncTask.new(session[:facebook], task: task).run
    
    redirect_to tasks_path and return
  end
end
