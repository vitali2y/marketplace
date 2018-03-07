module.exports =

  files:
    javascripts:
      joinTo:
        '/js/app.js': /^app/
        '/js/vendor.js': /^(?!app)/

    stylesheets:
      joinTo:
        'css/app.css': /^app/
        'css/vendor.css': /^(vendor\/css)/

    static_jade:
      extension: ".static.jade"
      path:      [ /^app/ ]

    babel:
      presets: [ 'es2015' ]

  sourceMaps:
    false

  minify:
    false

  optimize:
    false
