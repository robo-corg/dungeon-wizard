'use strict';

var watchify = require('watchify');
var browserify = require('browserify');
var gulp = require('gulp');
var source = require('vinyl-source-stream');
var buffer = require('vinyl-buffer');
var gutil = require('gulp-util');
var sourcemaps = require('gulp-sourcemaps');
var browserSync = require('browser-sync');
var assign = require('lodash').assign;

// add custom browserify options here
var customOpts = {
  entries: ['./src/js/app.coffee'],
  baseDir: './src/js/',
  extensions: ['.coffee'],
  paths: ['./src/js/'],
  debug: true
};
var opts = assign({}, watchify.args, customOpts);
//var b = watchify(browserify(customOpts)); 

var b = browserify(customOpts); 

gulp.task('js', bundle); // so you can run `gulp js` to build the file
b.on('update', bundle); // on any dep update, runs the bundler
b.on('log', gutil.log); // output build logs to terminal

function bundle() {
  return b.bundle()
    // log errors if they happen
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source('bundle.js'))
    // optional, remove if you don't need to buffer file contents
    .pipe(buffer())
    // optional, remove if you dont want sourcemaps
    .pipe(sourcemaps.init({loadMaps: true})) // loads map from browserify file
       // Add transformation tasks to the pipeline here.
    .pipe(sourcemaps.write('./')) // writes .map file
    .pipe(gulp.dest('./dist'));
}

// HTML
gulp.task('html', function() {
    return gulp.src('src/*.html')
        .pipe(gulp.dest('dist'))
});

gulp.task('build', ['html', 'js'])

gulp.task('watch', ['build'], function() {
    var bs = browserSync({
        notify: true,
        logPrefix: 'BS',
        // Run as an https by uncommenting 'https: true'
        // Note: this uses an unsigned certificate which on first access
        //       will present a certificate warning in the browser.
        // https: true,
        server: ['dist', 'src']
    });

    //bs.notify("HTML <span color='green'>is supported</span> too!");

    gulp.watch('./src/js/*.coffee', ['js']).on('change', function() {
        bs.reload("*.js");
    });

    // Watch .html files
    gulp.watch('src/*.html', ['html']);
});
