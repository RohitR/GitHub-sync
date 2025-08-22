require 'swagger_helper'

RSpec.describe 'API V1 Issues', type: :request do
  path '/api/v1/issues' do
    get('List issues') do
      tags 'Issues'
      produces 'application/json'
      parameter name: :state, in: :query, type: :string, description: 'Issue state (open/closed)', required: false

      response(200, 'successful') do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              number: { type: :integer },
              state:  { type: :string },
              title:  { type: :string },
              body:   { type: :string },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' },
              user: {
                type: :object,
                properties: {
                  login:      { type: :string },
                  avatar_url: { type: :string },
                  type:       { type: :string },
                  url:        { type: :string }
                }
              }
            },
            required: %w[number state title created_at updated_at user]
          }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: [
                {
                  number: 1,
                  state: 'closed',
                  title: 'first issue',
                  body: '',
                  created_at: '2017-04-18T11:01:48.000Z',
                  updated_at: '2017-04-18T11:01:51.000Z',
                  user: {
                    login: 'DominikAngerer',
                    avatar_url: 'https://avatars.githubusercontent.com/u/7952803?v=4',
                    type: 'User',
                    url: 'https://github.com/DominikAngerer'
                  }
                }
              ]
            }
          }
        end

        run_test!
      end
    end
  end
end
