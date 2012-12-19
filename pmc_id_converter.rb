# -*- coding: utf-8 -*-

require "json"
require "open-uri"

require "ap"

module PubMedIDConverter
  PMC_ids = ""
  PMC_file_list = ""
  
  def self.load_table(pmc_ids_path, pmc_file_list_path)
    PMC_ids <<  pmc_ids_path
    PMC_file_list << pmc_file_list_path
  end
  
  class PubMed
    def initialize(pmid)
      @pmid = pmid
    end
    
    def pubmed_xml
      eutil_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?"
      arg = "db=pubmed&id=#{@pmid}&retmode=xml"
      open(eutil_base + arg).read
    end
    
    def pmcid
      grepped = `grep #{@pmid} #{PMC_ids}`
      grepped.split(",")[8]
    end
  
    def pmc_xml_fname
      pmcid = self.pmcid
      if pmcid
        grepped = `grep #{pmcid} #{PMC_file_list}`
        parsed = grepped.split("\t")[1]
        if parsed
          journal_name = parsed.split(/\s\d{4}\s/).first.gsub(".","").gsub(" ","_")
          subbed = parsed.gsub(".","").gsub(";","").gsub(":","_").gsub(" ","_")
          journal_name + "/" + subbed + ".nxml"
        end
      end
    end
  end
end

def get_sra_publication
  url = "http://sra.dbcls.jp/cgi-bin/publication2.php"
  publications = open(url).read
  json_raw = JSON.parse(publications, :symbolize_names => true)
  json_raw[ :ResultSet ][ :Result ]
end

if __FILE__ == $0
  # INIT TABLE FOR ID CONVERTER
  pmc_ids_path = "./PMC-ids.csv"
  pmc_file_list_path = "./file_list.txt"
  PubMedIDConverter.load_table(pmc_ids_path, pmc_file_list_path)
  
  
  sra_publication = get_sra_publication
  pmid_in_sra = sra_publication.map{|record| record[:pmid] }.uniq
  
  pmcid_in_sra = pmid_in_sra.map{|pmid| PubMedIDConverter::PubMed.new(pmid).pmcid }.select{|n| n }.uniq
  
  pmc_xml_list = pmid_in_sra.map do |pmid|
    pm = PubMedIDConverter::PubMed.new(pmid)
    if pm.pmcid
      xml = pm.pmc_xml_fname
      ap pmid unless xml
    end
  end
  purified = pmc_xml_list.select{|n| n }.uniq

#  open("pmc_xml_list.json","w"){|f| JSON.dump(purified, f)}
  purified.each do |xml|
    base = "./pmc_xml/"
    fpath = base + xml
#    ap fpath unless File.exist?(fpath)
  end
end
