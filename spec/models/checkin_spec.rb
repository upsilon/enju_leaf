# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Checkin do
  fixtures :all

  it "should save checkout history if save_checkout_history is true" do
    user = users(:user1)
    checkouts_count = user.checkouts.count
    checkin = Checkin.new(:item => user.checkouts.not_returned.first.item, :basket => Basket.create(:user => users(:librarian1)))
    checkin.item_identifier = checkin.item.item_identifier
    checkin.save!
    checkin.item_checkin(user)
    user.checkouts.count.should eq checkouts_count
  end

  it "should not save checkout history if save_checkout_history is false" do
    user = users(:librarian1)
    checkouts_count = user.checkouts.count
    checkin = Checkin.new(:item => user.checkouts.not_returned.first.item, :basket => Basket.create(:user => users(:librarian1)))
    checkin.item_identifier = checkin.item.item_identifier
    checkin.save!
    checkin.item_checkin(user)
    user.checkouts.count.should eq checkouts_count - 1
  end
end

# == Schema Information
#
# Table name: checkins
#
#  id           :integer         not null, primary key
#  item_id      :integer         not null
#  librarian_id :integer
#  basket_id    :integer
#  created_at   :datetime
#  updated_at   :datetime
#

