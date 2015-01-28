Backbone = require('backbone')
Backbone.LocalStorage = require('backbone.localstorage')
_ = require('underscore')


class User extends Backbone.Model
  validate: (attrs, options) ->
    return 'email required' unless _.isString(attrs.email)
    return 'password required' unless _.isString(attrs.password)


class Users extends Backbone.Collection
  localStorage: new Backbone.LocalStorage('users')
  model: User


exports.User = User
exports.Users = Users
