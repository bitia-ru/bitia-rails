# frozen_string_literal: true

module Bitia
  module Purable
    extend ActiveSupport::Concern
    include ActionController::MimeResponds
    include Bitia::Resourceable

    included do
      respond_to :json

      before_action :purable_initialize_metavars
      before_action :purable_prepare_resources

      def index
        check_resource_prepared

        all = resources.count
        if params.include? :offset
          instance_variable_set("@#{resources_name}", resources.offset(params[:offset]))
        end
        if params.include? :limit
          instance_variable_set("@#{resources_name}", resources.limit(Integer(params[:limit])))
        end
        @metadata[:all] = all unless @metadata[:all]

        render_template
      end

      def new
        check_resource_prepared

        render_template
      end

      def show
        check_resource_prepared

        render_template
      end

      def create
        check_resource_prepared

        pure_create_or_update
        render_template
      end

      def update
        check_resource_prepared

        pure_create_or_update
        render_template
      end

      def destroy
        check_resource_prepared

        resource.destroy!

        render_template
      end

      def pure_filter(param)
        return unless params[param].present?

        resource.where!(param => params[param])
      end

      helper_method :pure_filter

      private

      def render_template
        @entities = (
          if params[:action] == 'index'
            resources
          elsif resource_params_present? && purable_resource_params.is_a?(Array)
            resources
          else
            resource
          end
        )

        render template: "bitia/api/#{params[:action]}"
      end

      def purable_initialize_metavars
        @resource = purable_model.name.underscore.to_sym
        @metadata ||= {}
        nil
      end

      def purable_prepare_resources
        if params[:action] == 'index'
          instance_variable_set("@#{resources_name}", purable_relation.all)
        elsif resource_params_present? && purable_resource_params.is_a?(Array)
          resources = purable_resource_params.map do |params|
            if params[:id].present? && params[:id] != 'self'
              purable_relation.find(params[:id]).tap { |r| r.assign_attributes(params) }
            else
              purable_relation.new(params)
            end
          end

          instance_variable_set("@#{resources_name}", resources)
        elsif %w[create update].include? params[:action]
          id = params.dig(resource_id_name)

          if id
            resource = purable_relation.find_by(resource_id_name => id)
            resource.assign_attributes(purable_resource_params)
          else
            resource = purable_relation.new(purable_resource_params)
          end
          instance_variable_set("@#{resource_name}", resource)
        else
          id = params[resource_id_name].present? ? params[resource_id_name] : purable_param_id

          instance_variable_set(
            "@#{resource_name}",
            id ? purable_relation.find_by(resource_id_name => id) : purable_relation.new
          )
        end
      rescue ActiveRecord::RecordNotFound => e
        self._prepare_resources_exception = e
      end

      def purable_param_id
        purable_resource_params[resource_id_name]
      rescue StandardError
        nil
      end

      def purable_relation
        purable_model_names_chain.inject(nil) do |m, pm|
          if m.nil?
            pm.singularize.classify.constantize
          elsif params.include?("#{m.to_s.underscore}_id")
            m.find(params["#{m.to_s.underscore}_id"]).send(pm.to_sym)
          elsif params.include?("#{m.to_s.underscore}_slug")
            m.find_by(slug: params["#{m.to_s.underscore}_slug"]).send(pm.to_sym) # TODO: uncovered
          end
        end
      end

      def pure_create_or_update
        if resources.present?
          purable_model.transaction { resources.each(&:save!) }
        else
          resource.save!
        end
      end

      def purable_resource_params
        send :"#{resource_name}_params"
      end

      def purable_model
        purable_model_chain.last
      end

      def purable_model_names_chain
        controller_path = self.class.controller_path.dup

        if defined?(self.class.controller_prefix) and self.class.controller_prefix.present?
          prefix_s = self.class.controller_prefix.map(&:to_s).join('/')
          raise StandardError, 'Bad prefix' if controller_path.index(prefix_s) != 0

          controller_path.sub! "#{prefix_s}/", ''
        end

        controller_path.split('/')
      end

      def purable_model_chain
        purable_model_names_chain.map { |p| p.singularize.classify.constantize }
      end

      def resource_params_present?
        [resource_name, resources_name].any? { |name| params.include? name.to_sym }
      end

      # rubocop:disable Style/MissingRespondToMissing
      def method_missing(method_name)
        resource_accessor_name = purable_model.name.underscore.to_sym

        return resource if method_name == resource_accessor_name

        super
      end
      # rubocop:enable Style/MissingRespondToMissing

      def check_resource_prepared
        if _prepare_resources_exception.present? and
           self.class._prepare_resources_fallback.present? and
           resource.nil? and
           resources.nil?
          raise _prepare_resources_exception
        end
      end

      class_attribute :_prepare_resources_fallback
      attr_accessor :_prepare_resources_exception
    end

    module ClassMethods
      def prepare_resources_fallback(fallback, *args, &block)
        self._prepare_resources_fallback = fallback

        before_action fallback, *args, &block
      end
    end
  end
end
