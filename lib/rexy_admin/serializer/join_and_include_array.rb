module RexyAdmin
  module Serializer
    class JoinAndIncludeArray
      prepend SimpleCommand
  
      def initialize(association, model)
        @association = association
        @model = model
      end
  
      def call
        join_and_include_array
      end

      def join_and_include_array
        to_join_and_include_array(model, associations[:associations])
      end

      def to_join_and_include_array(parent_model, associations)
        associations.map do |association|
          model_name = Helper.model_name association
          next(model_name) unless association.key?(:associations)
            
          child_model_names = to_join_and_include_array(association[:model], association[:associations])
          {model_name => [*child_model_names]}
        end
      end

      attr_accessor :association, :model
    end
  end
end
