# -*- encoding: utf-8 -*-
class LibrariesController < ApplicationController
  load_and_authorize_resource
  cache_sweeper :page_sweeper, :only => [:create, :update, :destroy]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /libraries
  # GET /libraries.json
  def index
    sort = {:sort_by => 'position', :order => 'asc'}
    case params[:sort_by]
    when 'name'
      sort[:sort_by] = 'name'
    end
    sort[:order] = 'desc' if params[:order] == 'desc'

    query = @query = params[:query].to_s.strip
    page = params[:page] || 1

    if query.present?
      @libraries = Library.search(:include => [:shelves]) do
        fulltext query
        paginate :page => page.to_i, :per_page => Library.per_page
        order_by sort[:sort_by], sort[:order]
      end.results
    else
      @libraries = Library.order("#{sort[:sort_by]} #{sort[:order]}").page(page)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.json { render :json => @libraries }
    end
  end

  # GET /libraries/1
  # GET /libraries/1.json
  def show
    search = Sunspot.new_search(Event)
    library = @library.dup
    search.build do
      with(:library_id).equal_to library.id
      order_by(:start_at, :desc)
    end
    page = params[:event_page] || 1
    search.query.paginate(page.to_i, Event.per_page)
    @events = search.execute!.results

    respond_to do |format|
      format.html # show.rhtml
      format.json { render :json => @library }
      format.js
    end
  end

  # GET /libraries/new
  def new
    @library = Library.new
    @library.country = LibraryGroup.site_config.country
    prepare_options
  end

  # GET /libraries/1;edit
  def edit
    prepare_options
  end

  # POST /libraries
  # POST /libraries.json
  def create
    #patron = Patron.create(:name => params[:library][:name], :patron_type => 'CorporateBody')
    @library = Library.new(params[:library])

    respond_to do |format|
      if @library.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.library'))
        format.html { redirect_to(@library) }
        format.json { render :json => @library, :status => :created }
      else
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @library.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /libraries/1
  # PUT /libraries/1.json
  def update
    if @library and params[:position]
      @library.insert_at(params[:position])
      redirect_to libraries_url
      return
    end

    respond_to do |format|
      if @library.update_attributes(params[:library])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.library'))
        format.html { redirect_to(@library) }
        format.json { head :ok }
      else
        @library.name = @library.name_was
        prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @library.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /libraries/1
  # DELETE /libraries/1.json
  def destroy
    @library.destroy

    respond_to do |format|
      format.html { redirect_to libraries_url }
      format.json { head :ok }
    end
  end

  private
  def prepare_options
    @library_groups = LibraryGroup.all
    @countries = Country.all_cache
  end
end
