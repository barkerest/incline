module Incline
  class AccessGroupsController < ApplicationController
    before_action :set_access_group, only: [:show, :edit, :update, :destroy]

    require_admin true

    ##
    # GET /incline/access_groups
    def index
      @access_groups = Incline::AccessGroup.all.sorted
    end

    ##
    # GET /incline/access_groups/1
    def show
    end

    ##
    # GET /incline/access_groups/new
    def new
      @access_group = Incline::AccessGroup.new
    end

    ##
    # GET /incline/access_groups/1/edit
    def edit
    end

    ##
    # POST /incline/access_groups
    def create
      @access_group = Incline::AccessGroup.create(access_group_params :before_create)
      if @access_group
        if @access_group.update(access_group_params :after_create)
          redirect_to incline.access_groups_url, notice: 'Access group was successfully created.'
        else
          render :new
        end
      else
        render :new
      end
    end

    ##
    # PATCH/PUT /incline/access_groups/1
    def update
      if @access_group.update(access_group_params)
        redirect_to incline.access_groups_url, notice: 'Access group was successfully updated.'
      else
        render :edit
      end
    end

    ##
    # DELETE /incline/access_groups/1
    def destroy
      @access_group.destroy
      redirect_to incline.access_groups_url, notice: 'Access group was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_access_group
      @access_group = Incline::AccessGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def access_group_params(mode = :all)
      list = []
      list += [ :name ] if mode == :before_create || mode == :all
      list += [ { group_ids: [], user_ids: [] } ] if mode == :after_create || mode == :all

      params.require(:access_group).permit(list)
    end
  end
end
