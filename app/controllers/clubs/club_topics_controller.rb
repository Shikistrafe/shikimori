class Clubs::ClubTopicsController < ShikimoriController
  load_and_authorize_resource :club
  load_and_authorize_resource class: Topic.name

  before_action { page_title i18n_i('Club', :other) }
  before_action :prepare_club
  # before_action :prepare_form, except: [:show]

  def index
  end

  def show
    raise AgeRestricted if @club.censored? && censored_forbidden?
    ensure_redirect! UrlGenerator.instance.topic_url(@resource)

    page_title i18n_i('Topic', :other)
    breadcrumb i18n_i('Topic', :other), club_club_topics_url(@club)

    @back_url = club_club_topics_url(@club)

    page_title @resource.title
    @topic_view = Topics::TopicViewFactory.new(false, false).build @club_topic
  end

  def new
    page_title i18n_t('new.title')
    render 'form'
  end

  def create
    @resource = Topic::Create.call faye, create_params, locale_from_host

    if @resource.persisted?
      redirect_to(
        UrlGenerator.instance.topic_url(@resource),
        notice: i18n_t('topic_created')
      )
    else
      flash[:alert] = t('changes_not_saved')
      new
    end
  end

  # def edit
    # page_title @resource.name
    # render 'form'
  # end

  # def update
    # if @resource.update update_params
      # redirect_to(
        # edit_club_club_page_path(@resource.club, @resource),
        # notice: t('changes_saved')
      # )
    # else
      # page_title @resource.name
      # flash[:alert] = t('changes_not_saved')
      # render 'form'
    # end
  # end

  # def destroy
    # @resource.destroy!
    # redirect_to @back_url, notice: i18n_t('destroy.success')
  # end

  # def up
    # @resource.move_higher
    # redirect_back(
      # fallback_location: edit_club_club_page_path(@resource.club, @resource)
    # )
  # end

  # def down
    # @resource.move_lower
    # redirect_back(
      # fallback_location: edit_club_club_page_path(@resource.club, @resource)
    # )
  # end

private

  def prepare_club
    @club = @club.decorate

    if %w[new create update destroy].include? params[:page]
      page_title t(:settings)
    end
    page_title t('clubs.page.pages.pages')

    breadcrumb i18n_i('Club', :other), clubs_url
    breadcrumb @club.name, club_url(@club)
  end

  def create_params
    params.require(:topic).permit(*TopicsController::CREATE_PARAMS)
  end
  alias new_params create_params

  def update_params
    params.require(:topic).permit(*TopicsController::UPDATE_PARAMS)
  end

  def faye
    FayeService.new current_user, faye_token
  end
end
