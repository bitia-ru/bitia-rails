class DogsController < Bitia::ApiController
  def authorize(_object)
    nil
  end

  private

  def dog_params
    if params.has_key?(:dogs)
      params.require(:dogs).map(&method(:single_dog_params))
    else
      single_dog_params(params.require(:dog))
    end
  end

  def single_dog_params(params)
    params.permit(:name)
  end
end