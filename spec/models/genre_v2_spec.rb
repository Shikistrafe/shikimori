describe GenreV2 do
  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :russian }
    it { is_expected.to validate_presence_of :mal_id }
  end

  describe 'enumerize' do
    it { is_expected.to enumerize(:kind).in(*Types::GenreV2::Kind.values) }
  end

  describe 'instance methods' do
    describe '#to_param' do
      before do
        subject.id = 123
        subject.name = 'Yaoi hentai'
      end
      its(:to_param) { is_expected.to eq '123-Yaoi-hentai' }
    end

    # describe '#title' do
    #   subject { genre.title ru_case: ru_case, user: user }
    #
    #   let(:ru_case) { :subjective }
    #   let(:user) { nil }
    #
    #   let(:genre) { build :genre_v2, name: name, entry_type: entry_type }
    #   let(:entry_type) { Types::GenreV2::EntryType['Anime'] }
    #   let(:name) { 'Romance' }
    #
    #   context 'Anime' do
    #     let(:entry_type) { Types::GenreV2::EntryType['Anime'] }
    #
    #     context 'Magic' do
    #       let(:name) { 'Magic' }
    #       it { is_expected.to eq 'Аниме про магию' }
    #     end
    #
    #     context 'Shounen' do
    #       let(:name) { 'Shounen' }
    #       it { is_expected.to eq 'Сёнен аниме' }
    #     end
    #
    #     context 'Romance' do
    #       let(:name) { 'Romance' }
    #       it { is_expected.to eq 'Романтические аниме про любовь' }
    #     end
    #   end
    #
    #   context 'Manga' do
    #     let(:entry_type) { Types::GenreV2::EntryType['Manga'] }
    #
    #     context 'Magic' do
    #       let(:name) { 'Magic' }
    #       it { is_expected.to eq 'Манга про магию' }
    #     end
    #
    #     context 'Shounen' do
    #       let(:name) { 'Shounen' }
    #       it { is_expected.to eq 'Сёнен манга' }
    #     end
    #
    #     context 'Romance' do
    #       let(:name) { 'Romance' }
    #       it { is_expected.to eq 'Романтическая манга про любовь' }
    #     end
    #   end
    #
    #   context 'genitive case' do
    #     let(:ru_case) { :genitive }
    #     it { is_expected.to eq 'Романтических аниме про любовь' }
    #   end
    #
    #   context 'default title' do
    #     let(:genre) { build :genre_v2, name: name, entry_type: entry_type, russian: 'Безумие' }
    #     let(:name) { 'Dementia' }
    #
    #     it { is_expected.to eq 'Аниме жанра безумие' }
    #   end
    # end
  end
end