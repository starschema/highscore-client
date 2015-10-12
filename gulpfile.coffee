gulp = require 'gulp'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
uglify = require 'gulp-uglify'

compileCoffee = (sources, destDir) ->
    gulp.src sources
    .pipe sourcemaps.init()
    .pipe coffee
        bare: true
    .on 'error', console.error
    .pipe sourcemaps.write '.'
    .pipe gulp.dest destDir

gulp.task 'coffee', ->
    sources = './src/*.coffee'
    destDir = './lib'
    compileCoffee sources, destDir

gulp.task 'browserify', ['coffee'], ->
    b = browserify
        entries: './lib/index.js'
        debug: true
    b.bundle()
        .pipe source 'index.js'
        .pipe buffer()
        .pipe sourcemaps.init {loadMaps: true}
           .pipe uglify
               mangle:
                   toplevel: true
               compress:
                   unsafe: true
        .pipe sourcemaps.write('../')
        .pipe gulp.dest 'static/'


gulp.task 'default', ['browserify']
