# Consyncful [![Build Status](https://travis-ci.org/boost/consyncful.svg?branch=master)](https://travis-ci.org/boost/consyncful)

Contentful -> local database synchronisation for Rails

Requesting complicated models from the Contentful Delivery API in Rails applications is often
too slow, and makes testing applications painful. Consyncful uses Contentful's syncronisation API 
to keep a local copy of the entire content in a Mongo database up to date.

Once the content is availble locally, finding and interact with contentful data is as easy as 
using [Mongoid](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-documents/) ODM. 

This gem doesn't provide any intergration with the management api or any way to update contentful models from the local store. It is strictly read only.

## Why do I have to use MongoDB?

Consyncful currently only supports Mongoid ODM because models have dynamic schemas. And that's all we've had a chance to work out so far. :) 
The same pattern might be able to be extended to work with ActiveRecord, but having to migrate the local database as well as your contentful content type's seems tedious.

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
class ModelWithReferences < Consyncful::Base
  contentful_model_name 'contentfulTypeName'

  references_one :thing
  references_many :other_things
end
```

### Syncronizing contentful data

To run a syncronization process run:

    $ rake consyncful:sync

The first time you run this it will download all the contentful content, it will then check every 15 seconds for changes to the content and update/delete records in the database when changes are made in contentful.

If you want to syncronise from scratch run:

    $ rake consyncful:refresh

It is recommended to refresh your data if you change model names.

Now you've synced your data, it is all available via your rails models

### Finding and interacting with models

#### Querying
Models are available using standard mongoid [queries](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-queries/).

```ruby
instance = ModelName.find_by(instance: 'foo')

instance.is_awesome # true
```

#### References
References work like you woule expect:

```ruby

instance = ModelWithReferences.find('contentfulID')

instance.thing # returns the referenced thing
instance.other_things # all the referenced things, polymorphic, so might be different types
```

**Except**:
`references_many` associations return objects in a different order from how they are ordered in contentful. If you want them in the order they appare in contentful, use the `.in_order` helper:

```ruby
instance.other_things.in_order # ordered the same as in contentful
```

#### Finding entrys from different content types

Because all contentful models are stored as polymorphic subtypes of Consyncful::Base, you can query all entries without knowing what type you are looking for:

```ruby
  Consyncful::Base.where(title: 'a title') # [ #<ModelName>, #<OtherModelName> ]
```

### Sync callbacks 

You may want to attach some application logic to happen before or after a sync run, for example to update caches or something. 

Callbacks can be registered using:

```ruby
Consyncful::Sync.before_run do
  # do something before the run
end
```

```ruby
Consyncful::Sync.after_run do |updated_ids|
  # invalidate cache for updated_ids, or something
end
```

## Limitations

### Locales

Current Consyncful only uses one globally configured locale to map the data to the database.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boost/consyncful.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
