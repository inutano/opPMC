# -*- coding: utf-8 -*-

require "nokogiri"
require "ap"

class PMCMetadataParser
  def initialize(xml)
    @nkgr = Nokogiri::XML(open(xml))
  end
  
  def journal_id
    @nkgr.css("journal-id").inner_text
  end
  
  def journal_title
    @nkgr.css("journal-title").inner_text
  end
  
  def publisher_name
    @nkgr.css("publisher-name").inner_text
  end
  
  def publisher_loc
    @nkgr.css("publisher-loc").inner_text
  end
  
  def article_title
    @nkgr.css("title-group article-title").inner_text
  end
  
  def authors
    @nkgr.css("contrib-group name").map do |node|
      node.css("surname").inner_text + "\s" + node.css("given-names").inner_text
    end
  end
  
  def ppub_date
    node = @nkgr.css("pub-date").select{|n| n.attr("pub-type").to_s == "ppub" }.first
    year = node.css("year").inner_text
    month = node.css("month").inner_text
    day = node.css("day").inner_text
    {year: year, month: month, day: day}
  end
  
  def epub_date
    node = @nkgr.css("pub-date").select{|n| n.attr("pub-type").to_s == "epub" }.first
    year = node.css("year").inner_text
    month = node.css("month").inner_text
    day = node.css("day").inner_text
    {year: year, month: month, day: day}
  end
  
  def abstract
    @nkgr.css("abstract").inner_text
  end
  
  def keywords
    @nkgr.css("kwd").map{|n| n.inner_text }
  end
  
  def body
    @nkgr.css("body").children.map do |node_section|
      sec_title = node_section.css("title").first.inner_text
      nodeset_subsec = node_section.css("sec")
      unless nodeset_subsec.empty?
        subsec = nodeset_subsec.map do |node_subsec|
          subsec_title = node_subsec.css("title").inner_text
          subsec_text = node_subsec.css("p").map{|n| n.inner_text }
          { subsec_title: subsec_title, subsec_text: subsec_text }
        end
        { sec_title: sec_title, subsec: subsec }
      else
        sec_text = node_section.css("p").map{|n| n.inner_text }
        { sec_title: sec_title, sec_text: sec_text }
      end
    end
  end
  
  def ref_journal_list
    cite = @nkgr.css("citation").select{|n| n.attr("citation-type").to_s == "journal" }
    cite.map do |node|
      article_title = node.css("article-title").inner_text
      pmid = node.css("pub-id").select{|n| n.attr("pub-id-type").to_s	== "pmid" }.first
      pmid = pmid.inner_text if pmid
      { article_title: article_title, pmid: pmid }
    end
  end
  
  def all
    { journal_id: self.journal_id,
      journal_title: self.journal_title,
      publisher_name: self.publisher_name,
      publisher_loc: self.publisher_loc,
      article_title: self.article_title,
      authors: self.authors,
      ppub_date: self.ppub_date,
      epub_date: self.epub_date,
      abstract: self.abstract,
      keywords: self.keywords,
      body: self.body,
      ref_journal_list: self.ref_journal_list }
  end
end


if __FILE__ == $0
  p = PMCMetadataParser.new("./test.xml")
  ap p.all
end