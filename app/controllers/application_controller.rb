# -*- encoding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied, :with => :render_403
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  rescue_from Errno::ECONNREFUSED, :with => :render_500
  rescue_from ActionView::MissingTemplate, :with => :render_404_invalid_format
  rescue_from ActionController::RoutingError, :with => :render_404

  before_filter :get_library_group, :set_locale, :set_available_languages, :prepare_for_mobile
  helper_method :mobile_device?

  private
  def render_403
    return if performed?
    if user_signed_in?
      respond_to do |format|
        format.html {render :template => 'page/403', :status => 403}
        format.mobile {render :template => 'page/403', :status => 403}
        format.xml {render :template => 'page/403', :status => 403}
        format.json
      end
    else
      respond_to do |format|
        format.html {redirect_to new_user_session_url}
        format.mobile {redirect_to new_user_session_url}
        format.xml {render :template => 'page/403', :status => 403}
        format.json
      end
    end
  end

  def render_404
    return if performed?
    respond_to do |format|
      format.html {render :template => 'page/404', :status => 404}
      format.mobile {render :template => 'page/404', :status => 404}
      format.xml {render :template => 'page/404', :status => 404}
      format.json
    end
  end

  def render_404_invalid_format
    return if performed?
    render :file => "#{Rails.root}/public/404.html"
  end

  def render_500
    Rails.logger.fatal("please confirm that the Solr is running.")
    return if performed?
    #flash[:notice] = t('page.connection_failed')
    respond_to do |format|
      format.html {render :file => "#{Rails.root.to_s}/public/500.html", :layout => false, :status => 500}
      format.mobile {render :file => "#{Rails.root.to_s}/public/500.html", :layout => false, :status => 500}
      format.xml {render :template => 'page/500', :status => 500}
      format.json
    end
  end

  def get_library_group
    @library_group = LibraryGroup.site_config
  end

  def set_locale
    if params[:locale]
      unless I18n.available_locales.include?(params[:locale].to_s.intern)
        raise InvalidLocaleError
      end
    end
    if user_signed_in?
      locale = params[:locale] || session[:locale] || current_user.locale.try(:to_sym)
    else
      locale = params[:locale] || session[:locale]
    end
    if locale
      I18n.locale = @locale = session[:locale] = locale.to_sym
    else
      I18n.locale = @locale = session[:locale] = I18n.default_locale
    end
  rescue InvalidLocaleError
    @locale = I18n.default_locale
  end

  def default_url_options(options={})
    {:locale => nil}
  end

  def set_available_languages
    if Rails.env == 'production'
      @available_languages = Rails.cache.fetch('available_languages'){
        Language.where(:iso_639_1 => I18n.available_locales.map{|l| l.to_s}).select([:id, :iso_639_1, :name, :native_name, :display_name, :position]).all
      }
    else
      @available_languages = Language.where(:iso_639_1 => I18n.available_locales.map{|l| l.to_s})
    end
  end

  def reset_params_session
    session[:params] = nil
  end

  def not_found
    raise ActiveRecord::RecordNotFound
  end

  def access_denied
    raise CanCan::AccessDenied
  end

  def get_patron
    @patron = Patron.find(params[:patron_id]) if params[:patron_id]
    authorize! :show, @patron if @patron
  end

  def get_work
    @work = Manifestation.find(params[:work_id]) if params[:work_id]
    authorize! :show, @work if @work
  end

  def get_expression
    @expression = Manifestation.find(params[:expression_id]) if params[:expression_id]
    authorize! :show, @expression if @expression
  end

  def get_manifestation
    @manifestation = Manifestation.find(params[:manifestation_id]) if params[:manifestation_id]
    authorize! :show, @manifestation if @manifestation
  end

  def get_item
    @item = Item.find(params[:item_id]) if params[:item_id]
    authorize! :show, @item if @item
  end

  def get_carrier_type
    @carrier_type = CarrierType.find(params[:carrier_type_id]) if params[:carrier_type_id]
  end

  def get_shelf
    @shelf = Shelf.find(params[:shelf_id], :include => :library) if params[:shelf_id]
  end

  def get_user
    @user = User.where(:username => params[:user_id]).first if params[:user_id]
    if @user
      authorize! :show, @user
    else
      raise ActiveRecord::RecordNotFound
    end
    return @user
  end

  def get_user_if_nil
    @user = User.where(:username => params[:user_id]).first if params[:user_id]
    #authorize! :show, @user if @user
  end

  def get_user_group
    @user_group = UserGroup.find(params[:user_group_id]) if params[:user_group_id]
  end

  def get_library
    @library = Library.find(params[:library_id]) if params[:library_id]
  end

  def get_libraries
    @libraries = Library.all_cache
  end

  def get_library_group
    @library_group = LibraryGroup.site_config
  end

  def get_bookstore
    @bookstore = Bookstore.find(params[:bookstore_id]) if params[:bookstore_id]
  end

  def get_series_statement
    @series_statement = SeriesStatement.find(params[:series_statement_id]) if params[:series_statement_id]
  end

  def get_subscription
    @subscription = Subscription.find(params[:subscription_id]) if params[:subscription_id]
  end

  if defined?(EnjuResourceMerge)
    def get_patron_merge_list
      @patron_merge_list = PatronMergeList.find(params[:patron_merge_list_id]) if params[:patron_merge_list_id]
    end
  end

  if defined?(EnjuQuestion)
    def get_question
      @question = Question.find(params[:question_id]) if params[:question_id]
      authorize! :show, @question if @question
    end
  end

  if defined?(EnjuEvent)
    def get_event
      @event = Event.find(params[:event_id]) if params[:event_id]
    end
  end

  if defined?(EnjuPurchaseRequest)
    def get_order_list
      @order_list = OrderList.find(params[:order_list_id]) if params[:order_list_id]
    end

    def get_purchase_request
      @purchase_request = PurchaseRequest.find(params[:purchase_request_id]) if params[:purchase_request_id]
    end
  end

  if defined?(EnjuCirculation)
    def get_basket
      @basket = Basket.find(params[:basket_id]) if params[:basket_id]
    end

    def get_checkout_type
      @checkout_type = CheckoutType.find(params[:checkout_type_id]) if params[:checkout_type_id]
    end
  end

  if defined?(EnjuInventory)
    def get_inventory_file
      @inventory_file = InventoryFile.find(params[:inventory_file_id]) if params[:inventory_file_id]
    end
  end

  if defined?(EnjuSubject)
    def get_subject_heading_type
      @subject_heading_type = SubjectHeadingType.find(params[:subject_heading_type_id]) if params[:subject_heading_type_id]
    end

    def get_subject
      @subject = Subject.find(params[:subject_id]) if params[:subject_id]
    end

    def get_classification
      @classification = Classification.find(params[:classification_id]) if params[:classification_id]
    end
  end

  def convert_charset
    case params[:format]
    when 'csv'
      return unless configatron.csv_charset_conversion
      # TODO: 他の言語
      if @locale.to_sym == :ja
        headers["Content-Type"] = "text/csv; charset=Shift_JIS"
        response.body = NKF::nkf('-Ws', response.body)
      end
    when 'xml'
      if @locale.to_sym == :ja
        headers["Content-Type"] = "application/xml; charset=Shift_JIS"
        response.body = NKF::nkf('-Ws', response.body)
      end
    end
  end

  def store_page
    flash[:page] = params[:page] if params[:page].to_i > 0
  end

  def store_location
    if request.get? and request.format.try(:html?) and !request.xhr?
      session[:user_return_to] = request.fullpath
    end
  end

  def set_role_query(user, search)
    role = user.try(:role) || Role.default_role
    search.build do
      with(:required_role_id).less_than role.id
    end
  end

  def make_internal_query(search)
    # 内部的なクエリ
    set_role_query(current_user, search)

    unless params[:mode] == "add"
      expression = @expression
      patron = @patron
      manifestation = @manifestation
      reservable = @reservable
      carrier_type = params[:carrier_type]
      library = params[:library]
      language = params[:language]
      if defined?(EnjuSubject)
        subject = params[:subject]
        subject_by_term = Subject.where(:term => params[:subject]).first
        @subject_by_term = subject_by_term
      end

      search.build do
        with(:publisher_ids).equal_to patron.id if patron
        with(:original_manifestation_ids).equal_to manifestation.id if manifestation
        with(:reservable).equal_to reservable unless reservable.nil?
        unless carrier_type.blank?
          with(:carrier_type).equal_to carrier_type
          with(:carrier_type).equal_to carrier_type
        end
        unless library.blank?
          library_list = library.split.uniq
          library_list.each do |library|
            with(:library).equal_to library
          end
          #search.query.keywords = "#{search.query.to_params[:q]} library_s: (#{library_list})"
        end
        unless language.blank?
          language_list = language.split.uniq
          language_list.each do |language|
            with(:language).equal_to language
          end
        end
        if defined?(EnjuSubject)
          unless subject.blank?
            with(:subject).equal_to subject_by_term.term
          end
        end
      end
    end
    return search
  end

  def solr_commit
    Sunspot.commit
  end

  def get_version
    @version = params[:version_id].to_i if params[:version_id]
    @version = nil if @version == 0
  end

  def clear_search_sessions
    session[:query] = nil
    session[:params] = nil
    session[:search_params] = nil
    session[:manifestation_ids] = nil
  end

  def api_request?
    true unless params[:format].nil? or params[:format] == 'html'
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, request.remote_ip)
  end

  def prepare_for_mobile
    request.format = :mobile if request.smart_phone?
  end

  def get_top_page_content
    if defined?(EnjuNews)
      @news_feeds = Rails.cache.fetch('news_feed_all'){NewsFeed.all}
      @news_posts = NewsPost.limit(3)
    end
    @libraries = Library.real
  end
end

class InvalidLocaleError < StandardError
end
