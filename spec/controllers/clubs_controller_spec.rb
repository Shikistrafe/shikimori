describe ClubsController do
  let(:club) { create :group }

  describe '#index' do
    let(:club) { create :group, :with_thread }
    let(:user) { create :user }
    let!(:group_role) { create :group_role, group: club, user: user, role: 'admin' }

    describe 'no_pagination' do
      before { get :index }
      it do
        expect(collection).to eq [club]
        expect(response).to have_http_status :success
      end
    end

    describe 'pagination' do
      before { get :index, page: 1 }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#show' do
    let(:club) { create :group, :with_thread }
    before { get :show, id: club.to_param }
    it { expect(response).to have_http_status :success }
  end

  describe '#new' do
    include_context :authenticated, :user
    before { get :new, club: { owner_id: user.id } }
    it { expect(response).to have_http_status :success }
  end

  describe '#edit' do
    include_context :authenticated, :user
    let(:club) { create :group, owner: user }
    before { get :edit, id: club.to_param }

    it { expect(response).to have_http_status :success }
  end

  describe '#create' do
    include_context :authenticated, :user

    context 'when success' do
      before { post :create, club: { name: 'test', owner_id: user.id } }
      it do
        expect(resource).to be_persisted
        expect(response).to redirect_to edit_club_url(resource)
      end
    end

    context 'when validation errors' do
      before { post :create, club: { owner_id: user.id } }

      it do
        expect(resource).to be_new_record
        expect(response).to have_http_status :success
      end
    end
  end

  describe '#update' do
    include_context :authenticated, :user
    let(:club) { create :group, :with_thread, owner: user }

    context 'when success' do
      context 'with kick_ids' do
        let(:user_2) { create :user }
        let!(:group_role) { create :group_role, group: club, user: user_2 }
        let(:kick_ids) { [user_2.id] }

        before { patch :update, id: club.id, club: { name: 'newnewtest' }, kick_ids: kick_ids }

        it do
          expect(club.reload.group_roles_count).to be_zero
          expect(resource.name).to eq 'newnewtest'
          expect(resource).to be_valid
          expect(response).to redirect_to edit_club_url(resource)
        end
      end

      context 'with admin_ids' do
        let(:user_2) { create :user }
        let!(:group_role) { create :group_role, group: club, user: user, role: 'admin' }
        let!(:group_role_2) { create :group_role, group: club, user: user_2 }
        let(:admin_ids) { [user.id, user_2.id] }

        before { patch :update, id: club.id, club: { name: 'newnewtest', admin_ids: admin_ids } }

        it do
          expect(club.reload.group_roles_count).to eq 2
          expect(club.admins).to eq [user, user_2]
          expect(resource.name).to eq 'newnewtest'
          expect(resource).to be_valid
          expect(response).to redirect_to edit_club_url(resource)
        end
      end
    end

    context 'when validation errors' do
      before { patch 'update', id: club.id, club: { name: '' } }

      it do
        expect(resource).to_not be_valid
        expect(response).to have_http_status :success
      end
    end
  end


  describe '#upload' do
    include_context :authenticated, :user
    let!(:group_role) { create :group_role, group: club, user: user, role: 'admin' }
    let(:image) { fixture_file_upload Rails.root.join('spec/images/anime.jpg'), 'image/jpeg' }
    before { post :upload, id: club.to_param, image: image }

    it do
      expect(club.images).to have(1).item
      expect(club.images.first.uploader).to eq user
      expect(response).to redirect_to club_url(club)
    end
  end

  describe '#members' do
    let(:club) { create :group }
    before { get :members, id: club.to_param }
    it { expect(response).to have_http_status :success }
  end

  describe '#images' do
    let(:club) { create :group }
    before { get :images, id: club.to_param }
    it { expect(response).to have_http_status :success }
  end

  describe '#comments' do
    let!(:section) { create :section, :club }
    let(:club) { create :group, :with_thread }
    let!(:comment) { create :comment, commentable: club.thread }
    before { get :comments, id: club.to_param }

    it { expect(response).to redirect_to section_topic_url(id: club.thread, section: section, linked: club) }
  end

  describe '#animes' do
    context 'without_animes' do
      before { get :animes, id: club.to_param }
      it { expect(response).to redirect_to club_url(club) }
    end

    context 'with_animes' do
      let(:club) { create :group, :with_thread, :linked_anime }
      before { get :animes, id: club.to_param }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#mangas' do
    context 'without_mangas' do
      before { get :mangas, id: club.to_param }
      it { expect(response).to redirect_to club_url(club) }
    end

    context 'with_mangas' do
      let(:club) { create :group, :with_thread, :linked_manga }
      before { get :mangas, id: club.to_param }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#characters' do
    context 'without_characters' do
      before { get :characters, id: club.to_param }
      it { expect(response).to redirect_to club_url(club) }
    end

    context 'with_characters' do
      let(:club) { create :group, :with_thread, :linked_character }
      before { get :characters, id: club.to_param }
      it { expect(response).to have_http_status :success }
    end
  end
end
