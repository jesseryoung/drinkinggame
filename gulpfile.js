var gulp = require('gulp'),
	watch = require('gulp-watch'),
	exec = require('child_process').exec;



var rcon = require('srcds-rcon')({
	address: '127.0.0.1',
	password: 'password'
});

gulp.task('watch', function() {
	return watch('src/**/*.sp', function() {
		console.log("Building...");
		exec("make", function(error, stdout, stderr) {
			console.log(stdout);
			console.log("Build finished - reloading plugin");
			rcon.connect().then(() => {
				return rcon.command('sm plugins refresh').then(() => {
					console.log('Reloaded plugin over rcon');
				});
			}).then(
				() => rcon.disconnect()
			).catch(err => {
				console.log('caught', err);
				console.log(err.stack);
			});
		});
	});
});