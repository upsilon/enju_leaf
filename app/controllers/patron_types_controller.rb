class PatronTypesController < InheritedResources::Base
  respond_to :html, :json
  load_and_authorize_resource

  def update
    @patron_type = PatronType.find(params[:id])
    if params[:position]
      @patron_type.insert_at(params[:position])
      redirect_to patron_types_url
      return
    end
    update!
  end

  def index
    @patron_types = @patron_types.page(params[:page])
  end
end
