class Admin::FeaturesController < Admin::BaseController
  # TODO: Add authentication/authorization check for admin users
  # before_action :require_admin_user

  before_action :set_feature, only: [ :show, :edit, :update, :destroy ]

  # GET /admin/features
  def index
    @features = Feature.unscoped.order(created_at: :desc) # Unscoped to ignore default date ordering for admin list
  end

  # GET /admin/features/1
  def show
  end

  # GET /admin/features/new
  def new
    @feature = Feature.new
  end

  # GET /admin/features/1/edit
  def edit
  end

  # POST /admin/features
  def create
    @feature = Feature.new(feature_params)

    if @feature.save
      redirect_to admin_feature_url(@feature), notice: "Feature was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/features/1
  def update
    if @feature.update(feature_params)
      redirect_to admin_feature_url(@feature), notice: "Feature was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/features/1
  def destroy
    @feature.destroy!
    redirect_to admin_features_url, notice: "Feature was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feature
      @feature = Feature.unscoped.find(params[:id]) # Use unscoped to find regardless of default scope
    end

    # Only allow a list of trusted parameters through.
    def feature_params
      params.expect(feature: [ :title, :description, :release_date, :image ])
    end
end
