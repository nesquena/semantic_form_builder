=begin

  This is the essential helper that defines the various standardized form elements
  that will be available for this application. Note that none of the methods
  below actually replace or override any existing field helpers but rather
  add an additional set of "standard" helpers which are items contained within
  a standardized "definition pair" with the label being inside a 'definition term'
  and the actual field within a 'definition data' in order to present a consistent
  and valid markup to the user for all forms.

  Using the field helpers below is easy and note that these same helpers can be accessed
  within model-backed forms by using the 'semantic_form_builder.rb' form builder.

  To use standard forms without a model:

    - form_tag some_url do
      - semantic_fieldset_tag "Name" do
        = semantic_text_field_tag     :username, :label => "Username"
        = semantic_password_field_tag :password, :label => "Password"
        = semantic_check_box_tag      :is_admin, :label => "Administrator?"
        = semantic_select_tag         :category, @option_values
        = semantic_submit_tag "Submit"

  To use standard forms with a model:

    - semantic_form_for :user, :url => register_url do |u|
      - u.fieldset do
        = u.text_field     "login"
        = u.password_field "password"
        = u.text_field     "email"
        = u.text_field     "mobile_number", :label => "Mobile No"
        = u.password_field "invite_code", :label => 'Invite'
        = u.submit_button

  To have standard fields within a fields_for a model:

    - semantic_fields_for :user do |u|
      - u.fieldset do 
        = u.text_field     "login"
        = u.password_field "password"

=end

module SemanticFormBuilder
  module Helpers
    
    # ===============================================================
    # FORM FIELD HELPERS
    # ===============================================================
    
    #
    # Check in "private helpers" lower in this file to see the definitions for:
    #
    #    - semantic_text_field_tag
    #    - semantic_password_fieldtag 
    #    - semantic_check_box_tag
    #    - semantic_text_area_tag
    #    - semantic_file_field_tag
    #
    # These were created dynamically in the method "self.create_field_element"
    #
    
    # creates a select tag that is generated within a definition item
    # for use within a definition form that has definition items for each field
    #
    #  option_values = options_for_select( [ 'foo', 'bar', 'other' ] )
    #
    #   <dt><label for="someid">Group</label></dt>
    #   <dd><select id="someid">...</select></dd> 
    #
    # ex: semantic_select_tag(:attribute, @option_values, :label => "example")
    #
    def semantic_select_tag(name, option_values, options={})
      label = options.delete(:label).gsub(' ', '&nbsp;')
      content_tag("dt", content_tag("label" , "#{label}:", :for => name )) +  "\n" +
      content_tag("dd", select_tag(name, option_values, options))
    end
    
    # places a submit_button in a standardized format with a definition item for a standard form.
    #
    #   <dt class="button"><label for="someid">Name</label></dt>
    #   <dd class="button"><input id="someid" type = 'submit' /></dd>
    #
    # ex: semantic_submit_tag "Caption"
    #
    def semantic_submit_tag(label, options={})
      html = tag(:dt, :class => 'button') 
      html << content_tag(:dd, :class => 'button') do
        submit_tag(label, options)
      end
    end
    
    # ===============================================================
    # FORM BLOCK HELPERS
    # ===============================================================
    
    # creates a regular form based on a model's data using the standard builder
    #
    # ex: semantic_form_for(:user, :url => users_path) do # ... end
    #
    def semantic_form_for(name, *args, &block)
      use_semantic_builder(:form_for, name, *args, &block)
    end
    
    # creates a remote form based on a model's data using the standard builder
    #
    # ex: semantic_remote_form_for(:user, :url => users_path) do # ... end
    #
    def semantic_remote_form_for(name, *args, &block)
      use_semantic_builder(:remote_form_for, name, *args, &block)
    end
    
    # creates a fields for based on a model's data using the standard builder
    #
    # ex: semantic_fields_for(:user, :url => users_path) do # ... end
    #
    def semantic_fields_for(name, *args, &block)
      use_semantic_builder(:fields_for, name, *args, &block)
    end
    
    # creates a ajaxy form based on a model's data using the standard builder
    # an ajaxy form is a form which automatically hides the submit button
    # and then shows an ajax loader when the submit button is clicked
    #
    # to make it work, the ajaxy form must have a special submit that is
    # created by using the 'submit_with_ajax' helper
    #
    # ex:
    #
    # - semantic_ajaxy_form_for :user, :url => create_user_url do |s|
    #   - s.fieldset do
    #     = f.text_field_item :login
    #     = submit_with_ajax_tag "Create"
    #
    def semantic_ajaxy_form_for(name, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      element_id = options[:html][:id] if options[:html]
      raise "Ajax form needs an identifying html id to be specified!" unless element_id
      options = options.reverse_merge!(:before => "ajaxyFormBefore('#{element_id}')", :complete => "ajaxyFormComplete('#{element_id}')")
      args = (args << options)
      use_semantic_builder(:remote_form_for, name, *args, &block)
    end
    
    # Creates a fieldset around the content block
    #
    #  <fieldset>
    #     <legend>Some Context</legend>
    #     <dl class="standard-form">
    #         ...block... 
    #     <dl>
    #   </fieldset>
    #
    # ex. 
    #
    #   semantic_fieldset_tag "Label" do
    #     ...input_fields...
    #   end
    #
    def semantic_fieldset_tag(name=nil, &block)
      content_block = capture(&block) # get the content
      field_set_tag(name) do
        content_tag(:dl, :class => "standard-form") do
          content_block
        end
      end
    end  
    
    # ===============================================================
    # PRIVATE HELPERS
    # ===============================================================
    
    private
    
    # given the element_name for the field and the options_hash will construct a hash
    # filled with all pertinent information for creating a field_tag with the correct details
    #
    # used by 'create_field_element' to retrieve the necessary field options for the field element
    #
    # element_name is simply a string or symbol representing the name of the field element such as "user[login]"
    # options_hash can have [ :id, :label, :value ]
    #
    # returns => { :value => 'field_value', :label => "some string", :id => 'some_id', ... }
    # 
    def field_tag_item_options(element_name, options)
      result_options = (options || {}).dup
      result_options[:id] ||= element_name
      result_options[:label]  ||= element_name.to_s.titleize
      result_options[:value]  ||= nil
      result_options
    end
    
    # adds a special option to any form helper block tags such as form_for, fields_for, remote_form_for
    # adds the option specifying that the "StandardBuilder" should be used to build the form
    # this is used when a statement should be made specialized to use this builder
    #
    # ex.
    #
    # def semantic_form_for(name, *args, &block)
    #   use_semantic_builder(:form_for, name, *args, &block)
    # end
    #
    def use_semantic_builder(method_name, name, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options = options.merge(:builder => SemanticFormBuilder::StandardBuilder)
      args = (args << options)
      method(method_name).call(name, *args, &block)
    end
    
    # places a xxxx_tag within the semantic defintion list formatting
    #
    #   <dt><label for="someid">Login</label></dt>
    #   <dd><input id="someid" ... /></dd>
    #
    # ex. semantic_text_field_tag :login, :label => "Login"
    # 
    # options hash can have { :id => "field id", :label => "field label", :value => "field value" ]
    #
    def self.create_field_element(input_type)
      method_name = "semantic_#{input_type}_tag" #i.e semantic_text_field_tag
      tag_name = "#{input_type}_tag" # i.e text_field_tag
      define_method(method_name) do |name, *args| # defines a method called 'semantic_text_field_tag' 
        field_helper_method = method(tag_name.intern)
        options = field_tag_item_options(name, args[0]) # grab the options hash
        
        html = content_tag(:dt) do
          content_tag(:label , "#{options.delete(:label)}:", :for => options[:id])
        end
        
        html << content_tag(:dd) do
          field_helper_method.call(name, options.delete(:value), options)
        end
        
      end
    end
    
    # for text, password, and check_boxes invoke the 'create_field_element' method to create
    # 'semantic_text_field_tag', 'semantic_password_field_tag', 'semantic_check_box_tag'
    # 'semantic_text_area_tag', 'semantic_file_field_tag'
    #
    [ 'text_field', 'password_field', 'check_box', 'file_field', 'text_area' ].each { |field| self.create_field_element(field) }
  end
end