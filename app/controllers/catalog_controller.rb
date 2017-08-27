# -*- encoding : utf-8 -*-
require 'ebsco/eds'

class CatalogController < ApplicationController

  include Blacklight::Eds::Catalog

  before_action :eds_init
  def eds_init
    guest = current_or_guest_user.guest
    if session.key?('guest')
      # user login/logon, update guest status in session
      if session['guest'] != guest
        session['guest'] = guest
        session['eds_session_token'] =
          EBSCO::EDS::Session.new(guest: guest,
                                  caller: 'status-changed').session_token
      end
    else
      # new user session, set guest and session token
      session['guest'] = guest
      session['eds_session_token'] =
        EBSCO::EDS::Session.new(guest: guest, caller: 'new-session').session_token
    end
    puts 'session token: ' + session['eds_session_token'].inspect
    puts 'session guest: ' + session['guest'].inspect
  end

  configure_blacklight do |config|

    config.default_solr_params = { rows: 10 }

    # solr field configuration for search results/index views
    config.index.title_field = :eds_title
    config.index.show_link = 'eds_title'
    config.index.record_display_type = 'eds_publication_type'
    config.index.thumbnail_field = 'eds_cover_medium_url'

    #config.add_index_field 'title_display', label: 'Title', :highlight => true
    config.add_index_field 'eds_authors', label: 'Author'
    config.add_index_field 'eds_publication_type', label: 'Format'
    config.add_index_field 'eds_source_title', label: 'Journal'
    config.add_index_field 'eds_languages', label: 'Language'
    config.add_index_field 'eds_publication_year', label: 'Year'
    config.add_index_field 'eds_publication_info', label: 'Published'
    config.add_index_field 'eds_fulltext_link', label: 'Fulltext', helper_method: :best_fulltext
    config.add_index_field 'eds_database_name', label: 'Database'
    config.add_index_field 'id'

    # solr field configuration for document/show views
    config.show.html_title = 'eds_title'
    config.show.heading = 'eds_title'
    config.show.display_type = 'eds_publication_type'
    config.show.pub_date = 'eds_publication_year'
    config.show.pub_info = 'eds_publication_info'
    config.show.abstract = 'eds_abstract'
    config.show.full_text_url = 'eds_fulltext_link'
    config.show.plink = 'eds_plink'

    config.add_facet_field 'eds_search_limiters_facet', label: 'Search Limiters'
    config.add_facet_field 'eds_publication_type_facet', label: 'Format'
    config.add_facet_field 'eds_library_location_facet', label: 'Library Location', limit: true
    config.add_facet_field 'eds_publication_year_facet', label: 'Publication Year', single: true
    config.add_facet_field 'eds_category_facet', label: 'Category', limit: 20
    config.add_facet_field 'eds_subject_topic_facet', label: 'Topic', limit: 20
    config.add_facet_field 'eds_language_facet', label: 'Language', limit: true, :multiple => true
    config.add_facet_field 'eds_journal_facet', label: 'Journals', limit: true
    config.add_facet_field 'eds_subjects_geographic_facet', label: 'Geography', limit: true
    config.add_facet_field 'eds_publisher_facet', label: 'Publisher', limit: true
    config.add_facet_field 'eds_content_provider_facet', label: 'Content Provider', limit: true
    config.add_facet_field 'eds_library_collection_facet', label: 'Library Collection', limit: true


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'eds_title', label: 'Title'
    config.add_show_field 'eds_source_title', label: 'Journal'
    config.add_show_field 'eds_authors', label: 'Author'
    config.add_show_field 'eds_publication_type', label: 'Format'
    config.add_show_field 'eds_publication_year', label: 'Publication Date'
    config.add_show_field 'eds_publication_info', label: 'Published'
    config.add_show_field 'eds_abstract', label: 'Abstract'
    config.add_show_field 'eds_document_doi', label: 'DOI', helper_method: :doi_link
    # config.add_show_field 'links', helper_method: :eds_links, label: 'Links'
    config.add_show_field 'eds_fulltext_link', label: 'Fulltext', helper_method: :best_fulltext
    config.add_show_field 'eds_html_fulltext', label: 'Full Text', helper_method: :html_fulltext

    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
          qf: '$title_qf',
          pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
          qf: '$author_qf',
          pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
          qf: '$subject_qf',
          pf: '$subject_pf'
      }
    end

    # Class for sending and receiving requests from a search index
    config.repository_class = Blacklight::Eds::Repository

    config.add_sort_field 'score desc', :label => 'most relevant'
    config.add_sort_field 'pub_date_sort desc', :label => 'most recent'
    #config.add_sort_field 'pub_date_sort asc', :label => 'oldest'

    # force spell checking in all cases, no max results required
    config.spell_max = 9999999999

  end
end