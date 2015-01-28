Backbone = require('backbone')
Backbone.$ = $ = require('jquery')
Ractive = require('ractive')

models = require('./lib/models.coffee')


class Router extends Backbone.Router
  el: $('main')

  initialize: ->
    @users = new models.Users
    @users.fetch()
    @view = null

  routes:
    '': 'index'
    'login': 'login'
    'register': 'register'
    'logout': 'logout'
    '*path': -> @navigate('', trigger: true)  # 404

  index: ->
    return unless @_enforce_auth()
    @view?.teardown?()
    @view = new Ractive
      el: @el
      template: require('./templates/index.html')
      data:
        tracks: [
          181645178
          180519630
          174279015
          169189226
        ]

    # Set up SoundCloud observers.
    @view.observe 'isAuthenticated', (isAuthenticated) ->
      return unless isAuthenticated
      tracks = @get('tracks')
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

  login: ->
    @view?.teardown?()
    @view = new Ractive
      el: @el
      template: require('./templates/login.html')

    @view.on 'login', (event) ->
      event.original.preventDefault()
      isValid = =>
        return false if @get('email') is ''
        return false if @get('password') is ''
        user = users.findWhere(email: @get('email'))
        return false unless user
        return false if user.get('password') isnt @get('password')
        true
      if not isValid()
        @set('loginInvalid', true)
      else
        localStorage.authUser = @get('email')
        @set('isAuthenticated', true)
        mixpanel.track('Login')
        mixpanel.identify(@get('email'))
        mixpanel.people.set
          '$last_login': new Date()

  register: ->
    @view?.teardown?()
    @view = new Ractive
      el: @el
      template: require('./templates/register.html')

    @view.on 'register', (event) ->
      event.original.preventDefault()

      isValid = =>
        return false if @get('email') is ''
        return false if @get('name') is ''
        return false if @get('password1') is ''
        return false if @get('password1') isnt @get('password2')
        return false if users.findWhere(email: @get('email'))
        true

      if not isValid()
        @set('registerInvalid', true)
      else
        user = users.create
          email: @get('email')
          name: @get('name')
          password: @get('password1')
        localStorage.authUser = user.get('email')
        @set('isAuthenticated', true)
        mixpanel.track('Register')
        mixpanel.identify(user.get('email'))
        mixpanel.people.set
          '$email': user.email
          '$created': new Date()
          '$last_login': new Date()
          'name': @get('name')


  logout: ->
    @view?.teardown?()
    delete localStorage.authUser
    mixpanel.track('Logout')
    @navigate('login', trigger: true)

  _enforce_auth: ->
    if not localStorage.authUser
      @navigate((if @users.length then 'login' else 'register'), trigger: true)
      return false
    true


exports.app = new Router()
Backbone.history.start()
