class ResourceGroupsController < ApplicationController
  before_action :set_resource_group, only: [:update, :destroy, :details, :activate, :deactivate, :remove_resource]

  def details
    @tasks = Task.where(resource_group_id: @resource_group.id, running: true)
  end

  def remove_resource
    resource = Resource.find(params[:resource_id])

    @resource_group.resources.delete(resource)

    redirect_to resource_group_details_path(@resource_group)
  end

  def activate
    ActiveRecord::Base.transaction do 
      @resource_group.resources.each do |res|
        res.activate
        res.save
      end
    end

    redirect_to resource_group_details_path(@resource_group)
  end

  def deactivate
    ActiveRecord::Base.transaction do 
      @resource_group.resources.each do |res|
        res.deactivate
        res.save
      end
    end

    redirect_to resource_group_details_path(@resource_group)
  end

  def mass_assign
    @resource_group = ResourceGroup.find(params[:group])

    params[:resources].each do |res_id|
      res = Resource.find(res_id)
      @resource_group.resources << res unless @resource_group.resources.include?(res)
    end

    @resource_group.save

    redirect_to root_path
  end

  # POST /resource_groups
  # POST /resource_groups.json
  def create
    @resource_group = ResourceGroup.new(resource_group_params)

    respond_to do |format|
      if @resource_group.save
        format.html { redirect_to resource_group_details_path(@resource_group), notice: 'Resource group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @resource_group }
      else
        format.html { render action: 'new' }
        format.json { render json: @resource_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /resource_groups/1
  # PATCH/PUT /resource_groups/1.json
  def update
    respond_to do |format|
      if @resource_group.update(resource_group_params)
        format.html { redirect_to @resource_group, notice: 'Resource group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @resource_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resource_groups/1
  # DELETE /resource_groups/1.json
  def destroy
    @resource_group.destroy
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resource_group
      @resource_group = ResourceGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_group_params
      params[:resource_group].permit(:group_name)
    end
end
