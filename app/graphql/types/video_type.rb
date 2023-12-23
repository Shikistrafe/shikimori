class Types::VideoType < Types::BaseObject
  field :id, ID, null: false
  field :name, String
  field :url, String, null: false
  field :kind, Types::Enums::Video::KindEnum, null: false
end
