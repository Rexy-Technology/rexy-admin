# RexyAdmin
### Table of Content
- [Introduction](#introduction)<br>
- [Dependencies](#dependencies)<br>
- [Installation](#installation)<br>
- [Configuration](#configuration)<br>
- [Example](#example)<br>
  - [Create models](#1-create-models)<br>
  - [Create a user and use jwt encode to get token](#2-create-a-user-and-use-jwt-encode-to-get-token)<br>
  - [Add RexyAdmin to Post model](#3-add-rexyadmin-to-post-model)<br>
  - [Make a request to create post](#4-make-a-request-to-create-post)<br>
  - [Set specify action](#5-set-specify-action)<br>
- [Features](#features)<br>
- [Contributing](#contributing)<br>
- [License](#license)<br>
- [Usage example](#usage-example)<br>

## Introduction
* As a developer, besides creating new things and "changing the world", we also have tasks that are boring, repetitive, but need to be done:
  * Authorization
  * CRUD
  * Query & search & pagination through models
  * ...
* RexyAdmin will automate these boring and repetitive tasks for you, so you will have more time to focus on the important things.
## Dependencies
* gem 'simple_command'
* gem 'params_checker'(optional)
* gem 'jwt'
* gem 'kaminari'
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
## Configuration
Config file json_web_token.rb for RexyAdmin's  authorization(at lib/json_web_token.rb)

```ruby
* # frozen_string_literal: true

class JsonWebToken
  # 2 days
  def self.encode(payload, exp = 30.days.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def self.decode(token)
    HashWithIndifferentAccess.new(JWT.decode(token, Rails.application.secrets.secret_key_base)[0])
  rescue StandardError
    nil
  end

  def self.dynamic_key_decode(token, key)
    HashWithIndifferentAccess.new(JWT.decode(token, key)[0])
  rescue StandardError
    nil
  end
end
```

Config initialize file config/initializers/rexy_admin.rb
```ruby
Rails.application.config.after_initialize do
  # is the model you use as the admin(to authorization)
  RexyAdmin.auth_model = User
  # use this if you want to use RexyAdmin's login feature
  RexyAdmin.use_rexy_admin_login = true
end
```

Include RexyAdmin to auth model for authorization
```ruby
class User < ApplicationRecord
  include RexyAdmin
end
```
## Example
### 1. Create models
  * We will create 4 models: User, Post, PostLike, Comment
  1. User<br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* User model
  ```ruby
  class User < ApplicationRecord
    include RexyAdmin
  end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* User columns
  ```ruby
    t.string :email
    t.string :name
    t.integer :age
  ```
  2. Post<br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Post model
  ```ruby
  class Post < ApplicationRecord
    has_many :comments
    has_many :post_likes

  end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Post columns
  ```ruby
    t.string :content
    t.boolean :active
    t.string :category
  ```
  3. Comment<br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Comment model
  ```ruby
  class Comment < ApplicationRecord
    belongs_to :post
    belongs_to :user
  end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* Comment columns
  ```ruby
    t.string :content
  ```
  4. PostLike<br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* PostLike model
  ```ruby
  class PostLike < ApplicationRecord
    belongs_to :post
    belongs_to :user
  end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* PostLike columns
  ```ruby
    t.boolean :like
  ```

### 2. Create a user and use jwt encode to get token
  Because we used model User as the auth model(in file config/initializers/rexy_admin.rb),now we will create a user by rails console
  ```
    user = User.create(email: 'ted@rexy.tech', name: 'ted', age: 
    21)
    JsonWebToken.encode admin_id: user.id
     => "eyJhbGciOiJIUzI1NiJ9.eyJhZG1pbl9pZCI6MywiZXhwIjoxNjA4MjY1NTExfQ.GQlZcfdUkVjq6P6agqKjN3SJ9YY54UlvpHccNwZs3pY"
  ```
### 3. Add RexyAdmin to Post model
  1. Include RexyAdmin to your model
  ```ruby
  class Post < ApplicationRecord
     has_many :comments
     has_many :post_likes

    include RexyAdmin
  end
  ```
  2. Define actions that you want to use
     * there are currently 6 actions: create, update, delete, show, toggle, index
     * if you want to only use rexyadmin for 3 actions(create, update, delete), you can define actions like this
  ```ruby
    class Post < ApplicationRecord
       has_many :comments
       has_many :post_likes

       include RexyAdmin
       use_actions only: %i[create update delete]
     end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* you can use :all if you want to use all actions
  ```ruby
    class Post < ApplicationRecord
       has_many :comments
       has_many :post_likes

       include RexyAdmin
       use_actions only: :all
     end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* or if you want to use all actions, except delete, you can define actions like this
  ```ruby
    class Post < ApplicationRecord
       has_many :comments
       has_many :post_likes

       include RexyAdmin
       use_actions except: %i[delete]
     end
  ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;* for simplicity, you will only use action :create for now
  ```ruby
    class Post < ApplicationRecord
       has_many :comments
       has_many :post_likes

       include RexyAdmin
       use_actions only: %i[create]
     end
  ```
### 4. Make a request to create post
  * method = POST
  * url = http://127.0.0.1:3000/rexy-admin/<model.table_name>/
    * Example: 
      * model = Post
      * Post.table_name => "posts"
      * => url = http://127.0.0.1:3000/rexy-admin/posts/
  * headers = {<br/>
      &nbsp;&nbsp;Content-Type: application/json,<br/>
      &nbsp;&nbsp;RexyAdmin-Authorization: the-token-you-just-created-at-step-2-with-jwt-encode<br/>
  }
  * data = {<br/>
    &nbsp;&nbsp; "content": "Do you know how much you save or spend each year?",<br/>
    &nbsp;&nbsp; "category": "financial",<br/>
    &nbsp;&nbsp; "active": "true"<br/>
  }
    * Is the fields of the post you want to create
```
  curl --request POST \
    --url http://127.0.0.1:3000/rexy-admin/posts/ \
    --header 'Content-Type: application/json' \
    --header 'RexyAdmin-Authorization: eyJhbGciOiJIUzI1NiJ9.eyJhZG1pbl9pZCI6MSwiZXhwIjoxNjA4MjA0NTMyfQ.47jEy2mH4ugFP30lm1qtBCydnSzFil9yqbXQdoF37mY' \
    --data '{
    "content": "Do you know how much you save or spend each year?",
    "category": "financial",
    "active": "true"
  }'
  => {"id": 7}
```
### 5. Set specify action
  * Now let's come to some real-life scenarios:
    1. What if we want to validate the post's fields data before we create it? Hypothesis, we want field "content" to be a maximum of 255 characters, or field "content" muse be uniq among other posts.
    2. We want to do extra things after creating a post, like, sending notifications.
  * That's when the set_action method comes in.
  ```ruby
    # example of usage of a set_action method
    set_action action: :create,
               params_checker: Posts::CreatePostValidate,
               command: Posts::CreatePost
  ```
  * if set_action is used for one of these actions: [:create, :update, :delete, :toggle], set_action has 3 keyword arguments:
    * action, is required
      * Receive the action you want to validate before executing or do extra things after validate(example: :create, :update, ...)
    * params_checker, is not required
      * Receive a ParamsChecker class from the [params-checker library](https://gitlab.com/rexylab/params-checker).
      * This ParamsCheckerClass will help you to validate the data and return errors if there are any
      * About the params-checker library: The library helps you to dynamically validate data input, custom validate, errors controllation,... with succinct syntax, easy to use, and help your code more clear.
      * Example: 
      ```ruby
        module Posts
          class CreatePostValidate < ParamsChecker::BaseParamsChecker
            def init
              {
                # content must be string, and can not exceed 255 characters, can be empty(content='')
                content: char_field(allow_blank: true),
                # category must be string, and can not exceed 255 characters, allow not present
                category: char_field(required: false),
                # active must be a boolean field(true or false)
                active: boolean_field,
              }
            end

            def check_content(content)
              add_error('Post content must be unique!') if Post.exists?(content: content)
              content
            end
          end
        end
      ```
    * command, is not required
      * Receive a class that prepends SimpleCommand. Read more [here](https://github.com/nebulab/simple_command).
      * Example:
      ```ruby
      module Posts
        class CreatePost
          prepend SimpleCommand

          def initialize(opts = {})
            # opts is the params that is sent from the request

            # example: {
            #   "content": "Do you know how much you save or spend each year?",
            #   "category": "financial",
            #   "active": "true"
            # }

            # if you use a ParamsChecker, the params will be validated 
            # and filtered first by ParamsChecker, then the filtered params
            # will be passed to this command as opts

            @opts = opts
          end

          def call
            # if you use a command in set_action, rexy admin will 
            # grant you full control(from create post, to send mail,
            # do other things...) instead of creating a post for you
            Post.create(opts)
            UserMailer.notifi_after_create_post(post).deliver_later
          end

          attr_accessor :opts
        end
      end
      ```
  * if set_action is used for action :toggle, set_action will have 1 additional keyword argument:
    * toggle_field
      * Receive field name that will be toggle
        * Example: :active
  * if set_action is used for one of these actions: [:index, :show], set_action has 8 keyword arguments:
    * action, is required
      * Receive the action you want to validate before executing or do extra things after validate(example: :create, :update, ...)
    * params_checker, is not required
      * Receive a ParamsChecker class from the [params-checker library](https://gitlab.com/rexylab/params-checker).
      * This ParamsCheckerClass will help you to validate the data and return errors if there are any
      * About the params-checker library: The library helps you to  dynamically validate data input, custom validate, errors control,... with succinct syntax, easy to use, and help your code more clear.
      * Example:
      ```ruby
        module Posts
          class CreatePostValidate < ParamsChecker::BaseParamsChecker
            def init
              {
                # content must be string, and can not exceed 255 characters, can be empty(content='')
                content: char_field(allow_blank: true),
                # category must be string, and can not exceed 255 characters, allow not present
                category: char_field(required: false),
                # active must be a boolean field(true or false)
                active: boolean_field,
              }
            end

            def check_content(content)
              add_error('Post content must be unique!') if Post.exists?(content: content)
              content
            end
          end
        end
      ```
    * fields, is not required
      * Are fields you want to get
        * Example: %i[content category active]
    * search_fields, is not required
      * Are fields you want to search
        * Example: %i[content category]
    * exclude_fields, is not required
      * Are fields you DON'T want to get
        * Example: %i[category active]
    * associations, is not required
      * Are the associations schema that RexyAdmin use to query
      ```ruby
         [{
           model: PostLike,
           fields: %i[id user_id post_id],
           associations: [{
             model: User,
             fields: %i[id email name],
             search_fields: %i[email name]
           }]
         },{
          model: Comment,
          fields: %i[id content user_id post_id],
          associations: [{
            model: User,
            fields: %i[id email name],
            search_fields: %i[email name]
          }]
        }]
      ```
    * after_query, is not required
      * Is the callback lambda you want to be executed after rexy admin query records from the database
        * Example an after_query method of action index:
          ```ruby
          # you can also use other params here
            # current_admin is the user that made request
            # params is the params of the request
          # lambda do |posts, current_admin, params|
          lambda do |posts|
            # posts are ActiveRecords
            posts.where(active: true)
          end
          ```
        * Example an after_query method of action show:
          ```ruby
          # you can also use other params here
            # current_admin is the user that made request
            # params is the params of the request
          # lambda do |post, current_admin, params|
          lambda do |post|
            # post is ActiveRecord
            post.where(active: true)
          end
          ```
    * after_action, is not required
      * Is the callback lambda you want to be executed before rexy admin return data to client
        * Example an after_action method of action index:
          ```ruby
          # you can also use other params here
            # current_admin is the user that made request
            # params is the params of the request
          # lambda do |posts, current_admin, params|
          lambda do |posts|
            # posts are an array of hashed
            posts.map do |post|
              post[:some_extra_field] = 'blabla'
            end
          end
          ```
        * Example an after_action method of action show:
          ```ruby
          # you can also use other params here
            # current_admin is the user that made request
            # params is the params of the request
          # lambda do |post, current_admin, params|
          lambda do |post|
            # post is a hash
            post[:some_extra_field] = 'blabla'
            post
          end
          ```
## Features
* Basic CRUD
  * create
    * is used to create one/multiple new records of a model
    * support create multiple records at once
    * support nested object(in construction)
  * update
    * is used to update an existing record of a model
    * support nested object(in construction)
  * delete
    * is used to destroy one/multiple existing records of a model
    * support destroy multiple records at once
  * show
    * is used to show one record data
    * support dynamically query other models
  * toggle
    * is used to toggle value true/false an optional field of an existing instance(active: true => active: false)
    * multiple toggle actions, with multiple different routes(in construction)
  * index
    * is used to list records(like a table)
    * support dynamically query other models
    * pagination
    * sort
    * search through other models
    * optional fields to get, optional fields to search
* Have a separated module(RexyAdmin::Serializer) to query/search/sort multiple models
```ruby
# a child has one mother and multiple siblings

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
    # a post that not exists in the database
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

    # auto remove posts that are not tracked
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

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
## Usage example
For more detail, you can clone [this](https://gitlab.com/rexy.tech/demorexyadmin) repo and examine the sample project.
****