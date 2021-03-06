require 'spec_helper'

describe "realize_types/new.html.erb" do
  before(:each) do
    assign(:realize_type, stub_model(RealizeType,
      :name => "MyString",
      :display_name => "MyText",
      :note => "MyText",
      :position => 1
    ).as_new_record)
  end

  it "renders new realize_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => realize_types_path, :method => "post" do
      assert_select "input#realize_type_name", :name => "realize_type[name]"
      assert_select "textarea#realize_type_display_name", :name => "realize_type[display_name]"
      assert_select "textarea#realize_type_note", :name => "realize_type[note]"
    end
  end
end
