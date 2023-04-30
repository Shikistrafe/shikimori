describe GenresV2Repository do
  let(:query) { described_class.instance }

  before { query.reset }

  it { expect(query).to be_kind_of RepositoryBase }

  describe '[]' do
    let!(:genre_v2) { create :genre_v2 }

    it do
      expect(query[genre_v2.id]).to eq genre_v2
      expect(query[2345678]).to eq nil
    end
  end

  describe '#find' do
    let(:mal_id) { 999_999_999 }

    context 'has entry' do
      let!(:entry) { create :genre_v2, mal_id: mal_id }
      it { expect(query.by_mal_id(mal_id)).to eq entry }
    end

    context 'no entry' do
      it do
        expect { query.by_mal_id mal_id }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'new entry' do
      let(:create_entry) { create :genre_v2, mal_id: mal_id }

      it do
        create_entry
        expect(query.by_mal_id(mal_id)).to eq create_entry
      end
    end
  end
end