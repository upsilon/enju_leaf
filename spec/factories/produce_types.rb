# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :produce_type do
    name { "MyString" }
    display_name { "MyText" }
    note { "MyText" }
  end
end
