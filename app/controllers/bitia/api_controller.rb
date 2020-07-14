# frozen_string_literal: true

class Bitia::ApiController < ActionController::Base
  include ActionController::MimeResponds

  respond_to :json

  include Resourceable

  before_action :purable_initialize_metavars
  before_action :purable_prepare_resources

  def index
    all = resources.count
    if params.include? :offset
      instance_variable_set("@#{resources_name}", resources.offset(params[:offset]))
    end
    if params.include? :limit
      instance_variable_set("@#{resources_name}", resources.limit(Integer(params[:limit])))
    end
    @metadata[:all] = all unless @metadata[:all]

    render
  end

  def new
    authorize resource
    render
  end

  def show
    authorize resource
    render
  end

  def create
    pure_create_or_update
    render
  end

  def update
    pure_create_or_update
    render
  end

  def destroy
    authorize resource
    resource.destroy!

    render
  end

  def pure_filter(param)
    return unless params[param].present?

    instance_variable_get("@#{resources_name}").where!(param => params[param])
  end

  helper_method :pure_filter

  def purable_model
    self.class.send(:purable_model)
  end

  helper_method :purable_model

  def purable_model_chain
    self.class.send(:purable_model_chain)
  end

  helper_method :purable_model

  private

  def purable_initialize_metavars
    @resource = purable_model.name.underscore.to_sym
    @metadata ||= {}
    nil
  end

  def purable_prepare_resources
    @current_user = User.find(params[:user_id]) if params.include? :user_id

    if params[:action] == 'index'
      instance_variable_set("@#{resources_name}", purable_relation.all)
    elsif params[:action] == 'show'
      id = params[:id].present? ? params[:id] : purable_param_id

      instance_variable_set(
        "@#{resource_name}", id ? purable_relation.find(id) : purable_relation.new
      )
    elsif purable_resource_params.is_a?(Array)
      resources = purable_resource_params.map do |params|
        if params[:id].present? && params[:id] != 'self'
          purable_relation.find(params[:id]).tap { |r| r.assign_attributes(params) }
        else
          purable_relation.new(params)
        end
      end

      instance_variable_set("@#{resources_name}", resources)
    else
      resource = purable_relation.new(purable_resource_params)
      instance_variable_set("@#{resource_name}", resource)
    end
  end

  def purable_param_id
    purable_resource_params[:id]
  rescue StandardError
    nil
  end

  def purable_relation
    purable_model_chain.inject(nil) do |m, pm|
      if m.nil?
        pm.singularize.classify.constantize
      elsif params.include?("#{m.to_s.underscore}_id")
        m.find(params["#{m.to_s.underscore}_id"]).send(pm.to_sym) # TODO: uncovered
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

  def self.purable_model_chain
    controller_path = self.controller_path.dup

    if defined?(controller_prefix) and controller_prefix.present?
      prefix_s = controller_prefix.map(&:to_s).join('/')
      raise StandardError, 'Bad prefix' if controller_path.index(prefix_s) != 0

      controller_path.sub! "#{prefix_s}/", ''
    end

    controller_path.split('/')
  end

  private_class_method :purable_model_chain

  def self.purable_model
    purable_model_chain.last.singularize.classify.constantize
  end

  private_class_method :purable_model

  def self.inherited(klass)
    resource_accessor_name = klass.send(:purable_model).name.underscore.to_sym
    klass.define_method(resource_accessor_name) { resource }
    klass.helper_method resource_accessor_name
  end

  private_class_method :inherited
end
