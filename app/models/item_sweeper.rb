class ItemSweeper < ActionController::Caching::Sweeper
  observe Item
  include ExpireEditableFragment

  def after_save(record)
    expire_editable_fragment(record)
    expire_editable_fragment(record.manifestation, ['detail', 'show_list', 'holding'])
    record.patrons.each do |patron|
      expire_editable_fragment(patron)
    end
    record.donors.each do |donor|
      expire_editable_fragment(donor)
    end
  end

  def after_destroy(record)
    after_save(record)
  end
end
