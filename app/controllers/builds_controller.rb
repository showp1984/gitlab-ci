class BuildsController < ApplicationController
  before_filter :authenticate_user!, except: [:status, :show]
  before_filter :project
  before_filter :authorize_access_project!, except: [:status, :show]

  def show
    unless @project.public || current_user
      authenticate_user! and return
    end
    @builds = builds

    @build = if params[:bid]
               @builds.where(id: params[:bid])
             else
               @builds
             end.limit(1).first


    raise ActiveRecord::RecordNotFound unless @build

    @builds = @builds.where("id not in (?)", @build.id).page(params[:page]).per(20)
  end

  def retry
    @build = builds.limit(1).first

    build = project.builds.create(
      sha: @build.sha,
      before_sha: @build.before_sha,
      push_data: @build.push_data,
      ref: @build.ref
    )

    redirect_to project_build_path(project, build)
  end

  def status
    @build = builds.limit(1).first

    render json: @build.to_json(only: [:status, :id, :sha])
  end

  def cancel
    @build = @project.builds.find(params[:id])
    @build.cancel

    redirect_to project_build_path(@project, @build)
  end

  protected

  def project
    @project = Project.find(params[:project_id])
  end

  def builds
    project.builds.where(sha: params[:id]).order('id DESC')
  end
end
