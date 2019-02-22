# Consyncful

Contentful to local database synchronisation for Rails

Requesting complicated models from the Contentful Delivery API in Rails applications is often
too slow, and makes testing applications painful. Consyncful uses Contentful's syncronisation API 
to keep a local copy of the entire content in a Mongo database up to date.

Once the content is availble locally, finding and interact with contentful data is as easy as 
using [Mongoid](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-documents/) ORM. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consyncful'
```

And then execute:

    $ bundle

If you don't already use mongoid, generate a mongoid.yml by running:

    $ rake g mongoid:config

Add an initializer:
Consyncful uses [contentful.rb](https://github.com/contentful/contentful.rb) so client options are as documented there.
```ruby
  Consyncful.configure do |config|
    config.locale = 'en-NZ'
    config.contentful_client_options = {
      api_url: 'cdn.contentful.com',
      space: 'space_id',
      access_token: 'ACCESS TOKEN',
      environment: 'master',        # optional
      logger: Logger.new(STDOUT)    # optional for debugging
    }
  end
```

## Usage

### Creating contentful models in your rails app

Create models by inheriting from `Consyncful::Base`

```ruby
class ModelName < Consyncful::Base
  contentful_model_name 'contentfulTypeName'
end
```

Model fields will be dynamicly assigned, but mongoid dynamic fields are not accessible if the entry has an empty field. If you want the accessor methods to be reliably available for fields it is recommended to define the fields in the model:

```ruby 
class ModelName < Consyncful::Base
  contentful_model_name 'contentfulTypeName'

  field :title
  field :is_awesome, type: Boolean
end
```

Contentful reference fields are a bit special compared with standard mongoid associations, Consyncful provides the following helpers to set up the correct relationships:

```ruby 
class ModelName < Consyncful::Base
  contentful_model_name 'contentfulTypeName'

  references_one :thing
  references_many :other_things
end
```

### Syncronizing contentful data

To run a syncronization process run:

    $ rake consyncful:sync

The first time you run this it will download all the contentful content, it will then check every 15 seconds for changes to the content and update/delete records in the database when changes are made in contentful.

If you want to delete everything and start syncronising from scratch run:

    $ rake consyncful:refresh

It is recommended to refresh your data if you change model names.

 


## Limitations

- locales (only one)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boost/consyncful.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
