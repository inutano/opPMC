# -*- coding: utf-8 -*-

require "json"
require "open-uri"

require "ap"

def get_sra_publication
  url = "http://sra.dbcls.jp/cgi-bin/publication2.php"
  publications = open(url).read
  json_raw = JSON.parse(publications, :symbolize_names => true)
  json_raw[ :ResultSet ][ :Result ]
end

def get_sra_pmc(pmc_ids_path, sra_publication)
  sra_pmc = sra_publication.map do |entry|
    sra_id = entry[:sra_id]
    pmid = entry[:pmid]
    grepped = `grep #{pmid} #{pmc_ids_path}`
    pmc_id = grepped.split(",")[8]
    pmc_id if pmc_id
  end
  sra_pmc.delete_if{|id| id == nil }.uniq
end

if __FILE__ == $0
  pmc_ids_path = "./PMC-ids.csv"
  sra_publication = get_sra_publication
  sra_pmc_id_json = "./sra_pmc_id.json"
  unless File.exist?(sra_pmc_id_json)
    sra_pmc_id = get_sra_pmc(pmc_ids_path, sra_publication)
    open(sra_pmc_id_json,"w"){|f| JSON.dump(sra_pmc_id, f) }
  else
    sra_pmc_id = open(sra_pmc_id_json){|f| JSON.load(f) }
  end
  
  table = "./file_list.txt"
  sra_pmc_id[0..9].each do |id|
    ap id
    ap `grep #{id} #{table}`
  end
end
