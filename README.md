# Consyncful

Contentful -> local database synchronisation for Rails

Requesting complicated models from the Contentful Delivery API in Rails applications is often too slow, and makes testing applications painful. Consyncful uses Contentful's synchronisation API to keep a local, up-to-date copy of the entire content in a Mongo database.

Once the content is available locally, finding and interact with contentful data is as easy as using [Mongoid](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-documents/) ODM.

This gem doesn't provide any integration with the management API, or any way to update Contentful models from the local store. It is strictly read only.

- [Installation](#installation)
- [Usage](#usage)
  - [Creating contentful models in your Rails app](#creating-contentful-models-in-your-rails-app)
  - [Synchronizing contentful data](#synchronizing-contentful-data)
  - [Finding and interacting with models](#finding-and-interacting-with-models)
    - [Querying](#querying)
    - [References](#references)
    - [Finding entries from different content types](#finding-entries-from-different-content-types)
  - [Sync callbacks](#sync-callbacks)
  - [Using Locales for specific fields](#using-locales-for-specific-fields)
  - [Configuring what Mongo database Consyncful uses](#configuring-what-mongo-database-consyncful-uses)
  - [Why do I have to use MongoDB?](#why-do-i-have-to-use-mongodb)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consyncful'
```

And then execute:

    $ bundle

If you don't already use Mongoid, generate a mongoid.yml by running:

    $ rake g mongoid:config

Add an initializer:

Consyncful uses [contentful.rb](https://github.com/contentful/contentful.rb); client options are as documented there.
```rb
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

### Creating contentful models in your Rails app

Create models by inheriting from `Consyncful::Base`

```ruby
class ModelName < Consyncful::Base
  contentful_model_name 'contentfulTypeName'
end
```

Model fields will be dynamically assigned, but Mongoid dynamic fields are not accessible if the entry has an empty field. If you want the accessor methods to be reliably available for fields it is recommended to define the fields in the model:

```ruby
class ModelName < Consyncful::Base
  contentful_model_name 'contentfulTypeName'

  field :title
  field :is_awesome, type: Boolean
end
```

Contentful reference fields are a bit special compared with standard Mongoid associations. Consyncful provides the following helpers to set up the correct relationships:

```ruby
class ModelWithReferences < Consyncful::Base
  contentful_model_name 'contentfulTypeName'

  references_one :thing
  references_many :other_things
end
```

### Synchronizing contentful data

To run a synchronization process run:

    $ rake consyncful:sync

The first time you run this it will download all the Contentful content. It will then check every 15 seconds for changes to the content and update/delete records in the database when changes are made in Contentful.

If you want to synchronise from scratch, run:

    $ rake consyncful:refresh

It is recommended to refresh your data if you change model names.

Now you've synced your data, it is all available via your Rails models.

### Finding and interacting with models

#### Querying
Models are available using standard Mongoid [queries](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-queries/).

```ruby
instance = ModelName.find_by(instance: 'foo')

instance.is_awesome # true
```

#### References
References work like you would expect:

```ruby

instance = ModelWithReferences.find('contentfulID')

instance.thing # returns the referenced thing
instance.other_things # all the referenced things, polymorphic, so might be different types
```

**Except**:
`references_many` associations return objects in a different order from how they are ordered in Contentful. If you want them in the order they appear in Contentful, use the `.in_order` helper:

```ruby
instance.other_things.in_order # ordered the same as in Contentful
```

#### Finding entries from different content types

Because all Contentful models are stored as polymorphic subtypes of `Consyncful::Base`, you can query all entries without knowing what type you are looking for:

```ruby
Consyncful::Base.where(title: 'a title') # [ #<ModelName>, #<OtherModelName> ]
```

### Sync callbacks

You may want to attach some application logic to happen before or after a sync run, for example to update caches.

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

### Using Locales for specific fields

If fields have multiple locales then the default locale will be mapped to the field name. Additional locales will have a suffix (lower snake case) on the field name. e.g title (default), title_mi_nz (New Zealand Maori mi-NZ)

### Sync specific contents using [Contentful Tag](https://www.contentful.com/help/tags/).
You can configure Consyncful to sync or ignore specific contents using Contentful Tag.

```rb
Consyncful.configure do |config|
  # Any contents tagged with 'myTag' will be stored in the database. 
  # Other contents without 'myTag' would be ignored.
  config.content_tags = ['myTag'] # defaults to []
end
```

Also, you can ignore contents with specific Tags.

```rb
Consyncful.configure do |config|
  # Any contents tagged with 'ignoreTag' won't be stored in the database.
  config.ignore_content_tags = ['ignoreTag'] # defaults to []
end
```

### Configuring what Mongo database Consyncful uses

You can also configure what Mongoid client Consyncful uses and the name of the collection the entries are stored under. This is useful if you want to have your consyncful data hosted in a different mongo database than your application-specific mongo database.

```rb
Consyncful.configure do |config|
  config.mongo_client = :consyncful # defaults to :default (referencing the clients in mongoid.yml)
  config.mongo_collection = 'contentful_models' # this is the default
end
```

### Why do I have to use MongoDB?

Consyncful currently only supports Mongoid ODM because models have dynamic schemas. And that's all we've had a chance to work out so far. The same pattern might be able to be extended to work with ActiveRecord, but having to migrate the local database as well as your contentful content type's seems tedious.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boost/consyncful.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
