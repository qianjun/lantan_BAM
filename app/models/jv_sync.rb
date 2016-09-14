#encoding: utf-8
class JvSync < ActiveRecord::Base
#  set_table_name :"lantan_db_all.jv_syncs"
  set_primary_key "id"

  TYPES = {:LANTAN_STORE => 0, :LANTAN_DB_ALL => 1, :LANTAN_DB => 2, :READ_AT => 3} #数据从哪里来



end


