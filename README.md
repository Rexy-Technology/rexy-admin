# RexyAdmin
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rexy_admin'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rexy_admin
```
## Features
* Basiq CRUD
	* create
		* can create multiple records at once
		* nested object(in construction)
	* update
		* nested object(in construction)
	* delete
		* can delete multiple records at once
	* show
		* use RexyAdmin::Serializer to show a record with multiple associations
	* toggle
		* toggle with optional field
		* multiple toggle actions, with multiple diffirent urls(in construction)
	* index
		* use RexyAdmin::Serializer to lists records with multiple associations
		* pagination
		* sort
		* search through multiple associations
		* optional fields to get, optional fields to search
* Have a separated module(RexyAdmin::Serializer) to query/search/sort multiple associations
```ruby
# a child have one mother and multiple siblings

schema = {
  model: Child,
  fields: %i[id name age],
  search_fields: %i[name],
  associations: [{
    model: Mother,
    fields: %i[id name age total_kids_count],
    search_fields: %i[name],
  },
  {
    model: Sibling,
    fields: %i[id name age],
    search_fields: %i[name],
  }]
}

cmd = RexyAdmin::Serializer::Serializer.call(
  schema: schema,
  many: true,
  paginate: true,
)

p cmd.result
=> 
{
  records: [
    {
      id: 1,
      name: 'Ted',
      age: 21,
      mother: {
        name: 'Snow white',
        age: 53,
        total_kids_count: 4
      },
      siblings: [{
        id: 1,
        name: 'Amy',
        age: 28,
      }]
  }]
  pagination: {
    page: 1,
    per_page: 10,
    total_count: 1
  }
}
```
* Have a separated module(RexyAdmin::FilterParams) to filter params of a model, modify params to nested object(in construction)
```ruby
# a user have multiple posts
params = {
  user_id: 1
  posts: [
    # update an existing post
    {
      id: 1,
      content: 'Updated content'
    },
    # a post that not exist in database
    {
      id: 1231213,
      content: 'Fake post data'
    },
    # create a new post
    {
      content: 'New post content'
    }
  ]
}

filtered_params = RexyAdmin::FilterParams.call(
    model: User,
    params: params,
    destroy_untracking_records: true
).result

p filtered_params
=> 
{
  user_id: 1
  post_attributes: [
    # update an existing post
    {
      id: 1,
      content: 'Updated content'
    },
    # the post with fake id(1231213) is removed

    # auto remove posts that not is not tracked
    {
      id: 3,
      content: 'Not tracking post',
      _destroy: true
    },
    # create a new post
    {
      content: 'New post content'
    }
  ]
}
```
* Multiple query routes(like multiple :index actions)
* Authorization with JWT
#Code/Documents/CoreTech/RexyAdmin#

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
