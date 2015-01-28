Backbone = require('backbone')
Backbone.LocalStorage = require('backbone.localstorage')
Ractive = require('ractive')

class User extends Backbone.Model
  validate: (attrs, options) ->
    return 'email required' unless _.isString(attrs.email)
    return 'password required' unless _.isString(attrs.password)


class Users extends Backbone.Collection
  localStorage: new Backbone.LocalStorage('users')
  model: User

Ractive.partials.loginForm = require('./templates/login.html')
Ractive.partials.registerForm = require('./templates/register.html')


ractive = new Ractive
  el: document.querySelector('main')
  template: '#main'
  data:
    isAuthenticated: !!localStorage.authUser
    doLogin: Object.keys(Users).length > 0
    tracks: [
      181645178
      180519630
      174279015
      169189226
    ]


# Set up SoundCloud observers.
ractive.observe 'isAuthenticated', (isAuthenticated) ->
  return unless isAuthenticated
  tracks = this.get('tracks')
  setTimeout ->
    for id in tracks
      widget = SC.Widget("track_#{id}")
      widget.bind SC.Widget.Events.PLAY, ->
        widget.getCurrentSound (sound) ->
          mixpanel.track 'Play', {
            id: sound._resource_id
            title: sound.title
            genre: sound.genre
            url: sound.permalink_url
          }


ractive.on 'login', (event) ->
  event.original.preventDefault()

  isValid = =>
    return false if this.get('email') is ''
    return false if this.get('password') is ''
    user = Users[this.get('email')]
    return false unless user
    return false if user.password isnt this.get('password')
    true

  if not isValid()
    this.set('loginInvalid', true)
  else
    localStorage.authUser = this.get('email')
    this.set('isAuthenticated', true)
    mixpanel.track('Login')
    mixpanel.identify(this.get('email'))
    mixpanel.people.set
      '$last_login': new Date()


ractive.on 'register', (event) ->
  event.original.preventDefault()

  isValid = =>
    return false if this.get('email') is ''
    return false if this.get('name') is ''
    return false if this.get('password1') is ''
    return false if this.get('password1') isnt this.get('password2')
    return false if this.get('email') in Object.keys(Users)
    true

  if not isValid()
    this.set('registerInvalid', true)
  else
    user =
      email: this.get('email')
      name: this.get('name')
      password: this.get('password1')
    Users[user.email] = user
    localStorage.users = JSON.stringify(Users)
    localStorage.authUser = user.email
    this.set('isAuthenticated', true)
    mixpanel.track('Register')
    mixpanel.identify(user.email)
    mixpanel.people.set
      '$email': user.email
      '$created': new Date()
      '$last_login': new Date()
      'name': this.get('name')


ractive.on 'logout', ->
  delete localStorage.authUser
  this.set('isAuthenticated', false)
  mixpanel.track('Logout')
