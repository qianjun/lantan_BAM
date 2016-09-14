#encoding: utf-8
namespace :del_terminate_c_pcard_rela do
  desc "delete all terminate or empty c_pcard_relations records "
  task(:delete_terminate_c_pcards_rela => :environment) do
    CPcardRelation.delete_terminate_cards
  end

end