describe ArticlesController do
  include_context :authenticated, :user, :week_registered

  describe '#index' do
    before { get :index }
    it { expect(response).to have_http_status :success }
  end

  describe '#new' do
    before { get :new, params: { article: { user_id: user.id } } }
    it { expect(response).to have_http_status :success }
  end

  describe '#create' do
    include_context :authenticated, :user, :week_registered

    context 'valid params' do
      before { post :create, params: { article: params } }
      let(:params) do
        {
          user_id: user.id,
          name: 'test',
          text: ''
        }
      end

      it do
        expect(resource).to be_persisted
        expect(response).to redirect_to edit_article_url(resource)
      end
    end

    context 'invalid params' do
      before { post :create, params: { article: params } }
      let(:params) { { user_id: user.id } }

      it do
        expect(resource).to be_new_record
        expect(response).to have_http_status :success
      end
    end
  end

  describe '#update' do
    include_context :authenticated, :user, :week_registered
    let(:article) { create :article, :with_topics, user: user }

    context 'valid params' do
      before do
        patch :update,
          params: {
            id: article.id,
            article: params
          }
      end
      let(:params) do
        {
          name: 'test article'
        }
      end
      let(:anime) { create :anime }

      it do
        expect(resource.reload).to have_attributes params
        expect(resource.errors).to be_empty
        expect(response).to redirect_to edit_article_url(resource)
      end
    end

    context 'invalid params' do
      before do
        patch 'update',
          params: {
            id: article.id,
            article: params
          }
      end
      let(:params) { { name: '' } }

      it do
        expect(resource.errors).to be_present
        expect(response).to have_http_status :success
      end
    end
  end

  describe '#destroy' do
    include_context :authenticated, :user, :week_registered
    let(:article) { create :article, user: user }
    before { delete :destroy, params: { id: article.id } }

    it do
      expect { article.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(response).to redirect_to articles_url
    end
  end
end
