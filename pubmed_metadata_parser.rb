# -*- coding: utf-8 -*-

require "nokogiri"

class PubMedMetadataParser
  def initialize(xml)
    @nkgr = Nokogiri::XML(xml)
  end
  
  def pmid
    @nkgr.css("MedlineCitation PMID").first.inner_text
  end
  
  def journal_title
    @nkgr.css("Journal Title").inner_text
  end
  
  def journal_isoabbreviation
    @nkgr.css("Journal ISOAbbreviation").inner_text
  end
  
  def article_title
    @nkgr.css("ArticleTitle").inner_text
  end
  
  def abstract
    @nkgr.css("AbstractText").inner_text
  end
  
  def affiliation
    @nkgr.css("Affiliation").inner_text
  end
  
  def authors
    @nkgr.css("AuthorList Author").map do |node|
      lastname = node.css("LastName").inner_text
      forename = node.css("ForeName").inner_text
      initial = node.css("Initials").inner_text
      { lastname: lastname, forename: forename, initial: initial }
    end
  end
  
  def comments_corrections
    @nkgr.css("CommentsCorrections").map do |node|
      ref_type = node.attr("RefType").to_s
      ref_source = node.css("RefSource").inner_text
      pmid = node.css("PMID").inner_text
      { ref_type: ref_type, ref_source: ref_source, pmid: pmid }
    end
  end
  
  def chemicals
    @nkgr.css("ChemicalList Chemical").map do |node|
      registry_number = node.css("RegistryNumber").inner_text
      name_of_substance = node.css("NameOfSubstance").inner_text
      { registry_number: registry_number, name_of_substance: name_of_substance }
    end
  end
  
  def mesh_terms
    @nkgr.css("MeshHeading").map do |node|
      descriptor_name = node.css("DescriptorName").inner_text
      qualifier_name = node.css("QualifierName").inner_text
      { descriptor_name: descriptor_name, qualifier_name: qualifier_name }
    end
  end
  
  def date_created
    year = @nkgr.css("DateCreated Year").inner_text
    month = @nkgr.css("DateCreated Month").inner_text
    day = @nkgr.css("DateCreated Day").inner_text
    { year: year, month: month, day: day }
  end
  
  def all
    { pmid: self.pmid,
      journal_title: self.journal_title,
      journal_isoabbreviation: self.journal_isoabbreviation,
      article_title: self.article_title,
      abstract: self.abstract,
      affiliation: self.affiliation,
      authors: self.authors,
      comments_corrections: self.comments_corrections,
      mesh_terms: self.mesh_terms,
      date_created: self.date_created }
  end
end

if __FILE__ == $0
  require "ap"
  require "./idconverter_pmc.rb"
  id_arr = ["22504184", "11250746", "21923928", "21888672"]
  id_arr.each do |id|
    xml = PubMedIDConverter::PubMed.new(id).pubmed_xml
    parser = PubMedMetadataParser.new(xml)
    ap parser.all
  end
end
