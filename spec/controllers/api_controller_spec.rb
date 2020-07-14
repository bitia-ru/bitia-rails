# frozen_string_literal: true

require 'rails_helper'

def render_dog(dog)
  {
    name: dog.name
  }
end

RSpec.describe DogsController, type: :controller do
  render_views

  before do
    routes.draw do
      resources :dogs
    end

    request.accept = 'application/json'
  end

  let!(:dog1) { create(:dog, name: 'Шарик') }
  let!(:dog2) { create(:dog, name: 'Бобик') }
  let!(:dog3) { create(:dog, name: 'Лайка') }

  describe ':index' do
    before { get :index }

    it 'should success' do
      expect(response).to have_http_status(:success)
    end

    it 'should return entities' do
      expect(response.body).to eq(
        JSON.dump(
          {
            metadata: {
              all: Dog.all.count
            },
            payload: Dog.all.map(&method(:render_dog))
          }
        )
      )
    end
  end

  describe ':show' do
    before do
      get :show, params: { id: dog2.id }
    end

    it 'should success' do
      expect(response).to have_http_status(:success)
    end

    it 'should return entity' do
      expect(response.body).to eq(
        JSON.dump(
          {
            metadata: {},
            payload: render_dog(dog2)
          }
        )
      )
    end
  end

  describe ':create' do
    context 'when single entity passed' do
      before do
        post :create, params: { dog: { name: 'Тузик' } }
      end

      it 'should success' do
        expect(response).to have_http_status(:success)
      end

      it 'should return entity' do
        expect(response.body).to eq(
          JSON.dump(
            {
              metadata: {},
              payload: { name: 'Тузик' }
            }
          )
        )
      end
    end
  end

  describe ':destroy' do
    # TODO
  end

  describe ':update' do
    # TODO
  end

  describe 'pure_filter' do
    # TODO
  end

  describe '@resource initialization' do
    it 'should be initialized correctly' do
      get :index

      expect(controller.instance_variable_get(:@resource)).to eq :dog
    end
  end

  describe 'resource preparing' do
    context 'create' do
      context 'single resource' do
        before do
          get :create, params: { dog: { name: 'Белка' } }
        end

        it 'should prepare correct resource' do
          expect(controller.resource.name).to eq 'Белка'
        end
      end

      context 'multiple resources' do
        let(:dogs_params) { { dogs: [{ name: 'Белка' }, { name: 'Стрелка' }] } }

        before do
          get :create, params: dogs_params
        end

        it 'should prepare correct resource' do
          expect(controller.resources&.map(&:name)).to eq(%w[Белка Стрелка])
        end

        it 'should create entities' do
          created_dogs = Dog.where(name: %w[Белка Стрелка]).all
          expect(created_dogs.map(&:name)).to contain_exactly('Белка', 'Стрелка')
        end
      end
    end
  end

  describe '#<purable_model.name.underscore.to_sym>' do
    it 'should call resource' do
      expect(controller).to receive(:resource).once

      controller.dog
    end
  end

  describe '#purable_model_chain' do
    context 'single controller' do
      before do
        allow(controller.class).to receive(:controller_path).and_return('foos')
      end

      it do
        expect(controller.class.purable_model_chain).to eq ['foos']
      end
    end

    context 'nested controller' do
      before do
        allow(controller.class).to receive(:controller_path).and_return('one/foo/baz/bar/xxxs')
      end

      after { controller.class.controller_prefix.clear }

      context 'without controller_prefix' do
        it 'should return correct value' do
          expect(controller.class.purable_model_chain).to eq %w[one foo baz bar xxxs]
        end
      end

      context 'with controller_prefix' do
        before do
          controller.class.controller_prefix_push 'one'
          controller.class.controller_prefix_push 'foo/baz'
        end

        it 'should return correct value' do
          expect(controller.class.purable_model_chain).to eq %w[bar xxxs]
        end
      end

      context 'with wrong controller_prefix' do
        before do
          controller.class.controller_prefix_push 'one'
          controller.class.controller_prefix_push 'foo/naz'
        end

        it 'should raise an exception' do
          expect { controller.class.purable_model_chain }.to raise_exception StandardError
        end
      end
    end
  end
end