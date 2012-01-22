module FileDelete
  
  # namespace our plugin and inherit from Rails::Railtie
  # to get our plugin into the initialization process
  class Railtie < Rails::Railtie

    # configure our plugin on boot. other extension points such
    # as configuration, rake tasks, etc, are also available
    initializer "newplugin.initialize" do |app|
      ActiveRecord::Base.send(:include, FileDelete)
      ActionView::Base.send(:include, FileDelete::ViewHelpers)
    end
  end
  
  def self.included(base)
    base.extend(ClassMethods)
    #models = ActiveRecord::Base.send(:subclasses)
    #puts "#{::Rails.root.to_s}/app/models/"
    #Dir["#{::Rails.root.to_s}/app/models/*"].each do |file|
    #  puts "trying to init #{file}\n"
    #  model = File.basename(file, ".*").classify.constantize
    #  models << model unless models.include?(model)
    #end
    #base.find_deletable_files(models)
  end
  
  module ClassMethods
    
        
    def find_del_files
      attachments = self.read_inheritable_attribute(:attachment_definitions)
      attachments.each do | attachment |
        puts "calling HDF for #{self} using #{attachment.first}\n"
        self.send(:has_deletable_file, attachment.first)
      end
    end
    
    def find_deletable_files(models)
      
      models.each do |model|
        attachments = model.read_inheritable_attribute(:attachment_definitions)
        attachments.each do | attachment |
          puts "calling HDF for #{model} using #{attachment.first}\n"
          model.send(:has_deletable_file, attachment.first)
        end
      end
      
    end
    
    def has_deletable_file name, options ={}
      
      before_validation "check_delete_#{name}".to_sym
            
      define_method "delete_#{name}=" do |value|
        self.instance_variable_set("@delete_#{name}".to_sym, !value.to_i.zero?)
        
      end
      
      define_method "delete_#{name}" do
        !!self.instance_variable_get("@delete_#{name}".to_sym)
        
      end
      
      alias_method "delete_#{name}?".to_sym, "delete_#{name}".to_sym
      
      define_method "check_delete_#{name}" do
         self.send(name).send(:destroy) if self.send("delete_#{name}?".to_sym) and !self.send(name).send(:dirty?)
      end
       
    end
  end
  
  module ViewHelpers
    def show_paperclip_attachment(f, object, method, deletable=true, options = {}, formtastic_options = {})
      res = ""
      if object.send(method).send(:exists?)
        content_type = object.send("#{method.to_s}_content_type".to_sym)
        if is_image content_type
          width = options[:width].nil? ? "200px" : options[:width]
          height = options[:height].nil? ? "" : options[:height]
          res += image_tag(object.send(method).send(:url), :width => width, :height => height)
        else
          res += link_to(object.send("#{method.to_s}_file_name".to_sym), object.send(method).send(:url), {:target => "_blank"})
        end
        if deletable 
          res += f.input "delete_#{method.to_s}".to_sym, :as => :boolean, :label => t('general.delete_file')

        end
      end
      res += f.input method, :as => :file, :input_html => options

      res
    end

    def is_image(content_type)
      if ['image/jpeg', 'image/png', 'image/gif','image/pjpeg'].include? content_type
        true
      else
        false
      end
    end
  end
end


