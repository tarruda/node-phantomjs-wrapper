module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffeelint:
      options:
        arrow_spacing: level: 'error'
        empty_constructor_needs_parens: level: 'error'
        non_empty_constructor_needs_parens: level: 'error'
        no_trailing_whitespace: level: 'error'
        no_empty_param_list: level: 'error'
        no_stand_alone_at: level: 'error'
        no_backticks: level: 'ignore'
        no_implicit_braces: level: 'ignore'
        space_operators: level: 'error'
      src:
        src: 'src/**/*.coffee'
      test:
        src: 'test/**/*.coffee'

    coffee_build:
        options:
          main: 'src/index.coffee'
          src: ['src/**/*.coffee', 'test/**/*.coffee']
        nodejs:
          options:
            dest: 'build'

    mocha_debug:
      options:
        check: ['src/**/*.coffee', 'test/**/*.coffee']
      all: [
        'test/setup.js'
        'build/**/*.js'
      ]
        
    clean:
      all: ['build']


  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-coffee-build'
  grunt.loadNpmTasks 'grunt-coffee-build'
  grunt.loadNpmTasks 'grunt-mocha-debug'
  grunt.loadNpmTasks 'grunt-release'

  grunt.registerTask 'rebuild', [
    'clean'
    'coffeelint'
    'coffee_build'
    'mocha_debug'
  ]

  grunt.registerTask 'publish', ['rebuild', 'release']

  grunt.registerTask 'default', [
    'coffeelint'
    'coffee_build'
    'mocha_debug'
  ]
