module.exports =

  paths:
    watched: [ '.', 'app', 'vendor' ]

  files:
    javascripts:
      joinTo:
        '/js/vendor.js': /^(?!app)/
        '/js/app.js': /^app/

    stylesheets:
      joinTo:
        'css/app.css': /^app/
        'css/vendor.css': /^(vendor\/css)/

  plugins:
    static_jade:
      extension: ".static.jade"
      path:      [ /^app/ ]

    plugins: babel: presets: [ 'es2015' ]

  sourceMaps:
    false

  minify:
    false

  optimize:
    false

  # debug configuration when using "npm run dev"
  server:
    path: './server/server.coffee'
    port: 3000
    base: ''
    run: true
