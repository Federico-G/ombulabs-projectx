class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_project, only: [:show, :edit, :update, :sort, :sort_stories, :destroy, :new_sub_project]

  def index
    @projects = Project.parents
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def sort
    params[:project].each_with_index do |id, index|
      @project.projects.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def sort_stories
    params[:story].each_with_index do |id, index|
      @project.stories.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def create
    @project = Project.new(projects_params)
    if @project.save
      flash[:success] = "Project created!"
      redirect_to @project
    else
      flash.now[:error] = @project.errors.full_messages
      render :new
    end
  end

  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_path, notice: "Project was successfully destroyed." }
    end
  end

  def show
    @sidebar_projects = @project.parent ? @project.parent.projects : @project.projects
    @stories = @project.stories.by_position.includes(:estimates)
    @siblings = @project.siblings
  end

  def update
    if @project.update(projects_params)
      respond_to do |format|
        format.html do
          flash[:success] = "Project updated!"
          redirect_to project_path(@project.id)
        end
        format.js do
          @sidebar_projects = @project.parent ? @project.parent.projects : @project.projects
        end
      end
    else
      flash[:error] = @project.errors.full_messages
      render :edit
    end
  end

  def new_sub_project
    @sub = Project.new(parent_id: @project)
  end

  private

  def find_project
    @project = Project.find(params[:id] || params[:project_id])
  end

  def projects_params
    params.require(:project).permit(:title, :status, :parent_id)
  end
end
