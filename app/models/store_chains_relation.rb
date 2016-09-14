class StoreChainsRelation < ActiveRecord::Base
  belongs_to :chain
  belongs_to :store

  def self.return_chain_stores(store_id)
    chain_ids = StoreChainsRelation.find_by_sql(["select scr.chain_id from store_chains_relations scr inner join chains c
        on c.id = scr.chain_id where c.status = ? and scr.store_id = ?", 
        Chain::STATUS[:NORMAL], store_id]).map { |item| item.chain_id}
    return chain_ids.any? ? StoreChainsRelation.where(:chain_id => chain_ids).map { |item| item.store_id }.compact.uniq : [store_id]
  end
  
end
