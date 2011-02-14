class ManifestationRelationshipsController < InheritedResources::Base
  load_and_authorize_resource
  helper_method :get_manifestation
  before_filter :prepare_options, :except => [:index, :destroy]

  def prepare_options
    @manifestation_relationship_types = ManifestationRelationshipType.all
  end

  def new
    @manifestation_relationship = ManifestationRelationship.new(params[:manifestation_relationship])
    @manifestation_relationship.parent = Manifestation.find(params[:manifestation_id])
    @manifestation_relationship.child = Manifestation.find(params[:child_id])
  end
end
